#!/bin/bash


# Copyright 2015  University of Illinois (Author: Amit Das)
# Copyright 2012-2015  Brno University of Technology (Author: Karel Vesely)

# Apache 2.0

# This example script trains Multi-lingual DNN with <BlockSoftmax> output, using FBANK features.
# The network is trained on multiple languages simultaneously, creating a separate softmax layer
# per language while sharing hidden layers across all languages.
# The script supports arbitrary number of languages.

. ./cmd.sh
. ./path.sh



active_block=1 
#./MTL/multitask.sh $stage $data_dir_csl $lang_code_csl $evaldir $ali_dir_csl $lang_weight_csl $graph_dir $mdlfile $nnet_type $expdir $datadir $nj
stage=$1 
data_dir_csl=$2 
lang_code_csl=$3 
evaldir=$4 
ali_dir_csl=$5 
lang_weight_csl=$6 
graph_dir=$7 
mdlfile=$8 
nnet_type=$9 
expdir=${10} 
datadir=${11} 
nj=${12}

echo "==================================================================="

echo stage=$stage
echo "==================================================================="




. utils/parse_options.sh || exit 1;

set -euxo pipefail

# Convert 'csl' to bash array (accept separators ',' ':'),
lang_code=($(echo $lang_code_csl | tr ',:' ' ')) 
ali_dir=($(echo $ali_dir_csl | tr ',:' ' '))
data_dir=($(echo $data_dir_csl | tr ',:' ' '))

# Make sure we have same number of items in lists,
! [ ${#lang_code[@]} -eq ${#ali_dir[@]} -a ${#lang_code[@]} -eq ${#data_dir[@]} ] && \
  echo "Non-matching number of 'csl' items: lang_code ${#lang_code[@]}, ali_dir ${ali_dir[@]}, data_dir ${#data_dir[@]}" && \
  exit 1
num_langs=${#lang_code[@]}

# Check if all the input directories exist,
for i in $(seq 0 $[num_langs-1]); do
  echo "lang = ${lang_code[$i]}, alidir = ${ali_dir[$i]}, datadir = ${data_dir[$i]}"
  [ ! -d ${ali_dir[$i]} ] && echo  "Missing ${ali_dir[$i]}" && exit 1
  [ ! -d ${data_dir[$i]} ] && echo "Missing ${data_dir[$i]}" && exit 1
done

# Make the features,
data=$datadir/data-fbank-multilingual${num_langs}-$(echo $lang_code_csl | tr ',' '-')
data_tr90=$data/combined_tr90
data_cv10=$data/combined_cv10
#================================================================================
if [ $stage -le 0 ]; then
  # Make local copy of data-dirs (while adding language-code),
  tr90=""
  cv10=""
  for i in $(seq 0 $[num_langs-1]); do
    code=${lang_code[$i]}
    dir=${data_dir[$i]}
    tgt_dir=$data/${code}_$(basename $dir)



 utils/copy_data_dir.sh --utt-prefix ${code}_ --spk-prefix ${code}_ $dir $tgt_dir; rm $tgt_dir/{feats,cmvn}.scp || true # remove features,
    # extract features, get cmvn stats,
    steps/make_fbank_pitch.sh --nj $nj --cmd "$train_cmd --max-jobs-run 10" $tgt_dir{,/log,/data}
    steps/compute_cmvn_stats.sh $tgt_dir{,/log,/data}
    # split lists 90% train / 10% held-out,
#    utils/subset_data_dir_tr_cv.sh $tgt_dir ${tgt_dir}_tr90 ${tgt_dir}_cv10
  MTL/subset_data_dir_tr_cv2.sh $tgt_dir ${tgt_dir}_tr90 ${tgt_dir}_cv10

    tr90="$tr90 ${tgt_dir}_tr90"
    cv10="$cv10 ${tgt_dir}_cv10"
  done
  # Merge the datasets,
  utils/combine_data.sh $data_tr90 $tr90
  utils/combine_data.sh $data_cv10 $cv10
  # Validate,
  utils/validate_data_dir.sh $data_tr90  
  utils/validate_data_dir.sh $data_cv10  
fi



# Extract the tied-state numbers from transition models,
for i in $(seq 0 $[num_langs-1]); do
  ali_dim[i]=$(hmm-info ${ali_dir[i]}/final.mdl | grep pdfs | awk '{ print $NF }')
done
ali_dim_csl=$(echo ${ali_dim[@]} | tr ' ' ',')

# Total number of DNN outputs (sum of all per-language blocks),
output_dim=$(echo ${ali_dim[@]} | tr ' ' '\n' | awk '{ sum += $i; } END{ print sum; }')
echo "Total number of DNN outputs: $output_dim = $(echo ${ali_dim[@]} | sed 's: : + :g')"

# Objective function string (per-language weights are imported from '$lang_weight_csl'),
objective_function="multitask$(echo ${ali_dim[@]} | tr ' ' '\n' | \
  awk -v w=$lang_weight_csl 'BEGIN{ split(w,w_arr,/[,:]/); } { printf(",xent,%d,%s", $1, w_arr[NR]); }')"
echo "Multitask objective function: $objective_function"

# DNN training will be in $dir, the alignments are prepared beforehand,
dir=$expdir/dnn4g-multilingual${num_langs}-$(echo $lang_code_csl | tr ',' '-')-$(echo $lang_weight_csl | tr ',' '-')-${nnet_type}
[ ! -e $dir ] && mkdir -p $dir
echo "$lang_code_csl" >$dir/lang_code_csl
echo "$ali_dir_csl" >$dir/ali_dir_csl
echo "$data_dir_csl" >$dir/data_dir_csl
echo "$ali_dim_csl" >$dir/ali_dim_csl
echo "$objective_function" >$dir/objective_function
#================================================================================
# Prepare the merged targets,
if [ $stage -le 1 ]; then
  [ ! -e $dir/ali-post ] && mkdir -p $dir/ali-post
  # re-saving the ali in posterior format, indexed by 'scp',
  for i in $(seq 0 $[num_langs-1]); do
    code=${lang_code[$i]}
    ali=${ali_dir[$i]}
    # utt suffix added by 'awk',
    ali-to-pdf $ali/final.mdl "ark:gunzip -c ${ali}/ali.*.gz |" ark,t:- | awk -v c=$code '{ $1=c"_"$1; print $0; }' | \
      ali-to-post ark:- ark,scp:$dir/ali-post/$code.ark,$dir/ali-post/$code.scp
  done
  # pasting the ali's, adding language-specific offsets to the posteriors,
  featlen="ark:feat-to-len 'scp:cat $data_tr90/feats.scp $data_cv10/feats.scp |' ark,t:- |" # get number of frames for every utterance,
  post_scp_list=$(echo ${lang_code[@]} | tr ' ' '\n' | awk -v d=$dir '{ printf(" scp:%s/ali-post/%s.scp", d, $1); }')
  paste-post --allow-partial=true "$featlen" "${ali_dim_csl}" ${post_scp_list} \
    ark,scp:$dir/ali-post/combined.ark,$dir/ali-post/combined.scp
fi

# Train the <BlockSoftmax> system, 1st stage of Stacked-Bottleneck-Network,
if [ $stage -le 2 ]; then  
  case $nnet_type in
    bn)
    # Bottleneck network (40 dimensional bottleneck is good for fMLLR),
    $cuda_cmd $dir/log/train_nnet.log \
      steps/nnet/train.sh --learn-rate 0.008 \
        --hid-layers 2 --hid-dim 1500 --bn-dim 40 \
        --cmvn-opts "--norm-means=true --norm-vars=false" \
        --feat-type "traps" --splice 5 --traps-dct-basis 6 \
        --labels "scp:$dir/ali-post/combined.scp" --num-tgt $output_dim \
        --proto-opts "--block-softmax-dims=${ali_dim_csl}" \
        --train-tool "nnet-train-frmshuff --objective-function=$objective_function" \
        ${data_tr90} ${data_cv10} lang-dummy ali-dummy ali-dummy $dir
    ;;
    sbn)
    # Stacked Bottleneck Netowork, no fMLLR in between,
    bn1_dim=80
    bn2_dim=30
    # Train 1st part,
    dir_part1=${dir}_part1
    $cuda_cmd ${dir}_part1/log/train_nnet.log \
      steps/nnet/train.sh --learn-rate 0.008 \
        --hid-layers 2 --hid-dim 1500 --bn-dim $bn1_dim \
        --cmvn-opts "--norm-means=true --norm-vars=false" \
        --feat-type "traps" --splice 5 --traps-dct-basis 6 \
        --labels "scp:$dir/ali-post/combined.scp" --num-tgt $output_dim \
        --proto-opts "--block-softmax-dims=${ali_dim_csl}" \
        --train-tool "nnet-train-frmshuff --objective-function=$objective_function" \
        ${data_tr90} ${data_cv10} lang-dummy ali-dummy ali-dummy $dir_part1
    # Compose feature_transform for 2nd part,
    nnet-initialize <(echo "<Splice> <InputDim> $bn1_dim <OutputDim> $((13*bn1_dim)) <BuildVector> -10 -5:5 10 </BuildVector>") \
      $dir_part1/splice_for_bottleneck.nnet 
    nnet-concat $dir_part1/final.feature_transform "nnet-copy --remove-last-components=4 $dir_part1/final.nnet - |" \
      $dir_part1/splice_for_bottleneck.nnet $dir_part1/final.feature_transform.part1
    # Train 2nd part,
    $cuda_cmd $dir/log/train_nnet.log \
      steps/nnet/train.sh --learn-rate 0.008 \
        --feature-transform $dir_part1/final.feature_transform.part1 \
        --hid-layers 2 --hid-dim 1500 --bn-dim $bn2_dim \
        --labels "scp:$dir/ali-post/combined.scp" --num-tgt $output_dim \
        --proto-opts "--block-softmax-dims=${ali_dim_csl}" \
        --train-tool "nnet-train-frmshuff --objective-function=$objective_function" \
        ${data_tr90} ${data_cv10} lang-dummy ali-dummy ali-dummy $dir
    ;;
    dnn_small)
    # 4 hidden layers, 1024 sigmoid neurons,  
    $cuda_cmd $dir/log/train_nnet.log \
      steps/nnet/train.sh --learn-rate 0.008 \
        --cmvn-opts "--norm-means=true --norm-vars=true" \
        --delta-opts "--delta-order=2" --splice 5 \
        --labels "scp:$dir/ali-post/combined.scp" --num-tgt $output_dim \
        --proto-opts "--block-softmax-dims=${ali_dim_csl}" \
        --train-tool "nnet-train-frmshuff --objective-function=$objective_function" \
        ${data_tr90} ${data_cv10} lang-dummy ali-dummy ali-dummy $dir
    ;;
    dnn)
    # 6 hidden layers, 2048 simgoid neurons,
    $cuda_cmd $dir/log/train_nnet.log \
      steps/nnet/train.sh --learn-rate 0.008 \
        --hid-layers 6 --hid-dim 2048 \
        --cmvn-opts "--norm-means=true --norm-vars=false" \
        --delta-opts "--delta-order=2" --splice 5 \
        --labels "scp:$dir/ali-post/combined.scp" --num-tgt $output_dim \
        --proto-opts "--block-softmax-dims=${ali_dim_csl}" \
        --train-tool "nnet-train-frmshuff --objective-function=$objective_function" \
        ${data_tr90} ${data_cv10} lang-dummy ali-dummy ali-dummy $dir
    ;;
    *)
    echo "Unknown --nnet-type $nnet_type"; exit 1;
    ;;
  esac
fi



#================================================================
# Decoding stage 
if [ $stage -le 3 ]; then
L=${lang_code[0]}     # the first lang is the test language
#exp_dir=${ali_dir[0]} # this should be a gmm dir



  case $nnet_type in
    dnn_small)
      echo "Decoding $L"

          decode_dir=$dir/decode_block_${active_block}
          # extract the active softmax from block softmax
	./MTL/make_activesoftmax_from_blocksoftmax.sh $dir/final.nnet "$(echo ${ali_dim_csl}|tr ':' ',')" $active_block $decode_dir/final.nnet
		  # make other necessary dependencies available
          #(cd $decode_dir; ln -s {$mdlfile,../final.feature_transform,norm_vars,delta_order,../cmvn_opts,../delta_opts} . ;)
	  (cd $decode_dir; ln -s {../final.feature_transform,norm_vars,delta_order,../cmvn_opts,../delta_opts} . ;)

	 cp $mdlfile $decode_dir
          # create "prior_counts"        
          steps/nnet/make_priors.sh --use-gpu "yes" $data_tr90 $decode_dir
          # finally, decode
          (steps/nnet/decode.sh --nj $nj --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.2 --srcdir $decode_dir \
	        $graph_dir $evaldir $decode_dir || exit 1;) 
	  
    ;;
    *)
      echo "Decoding not supported for --nnet-type $nnet_type"; exit 1;
    ;;
  esac
fi



#done
