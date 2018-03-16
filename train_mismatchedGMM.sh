#!/bin/bash -e

# train mismatched GMM acoustic model

[ -f cmd.sh ] && source ./cmd.sh \
  || echo "cmd.sh not found. Jobs may not execute properly."

. path.sh || { echo "Cannot source path.sh"; exit 1; }




traindir=$1
exp=$2
langdir=$3
NUMLEAVES=$4
NUMGAUSSIANS=$5
stage=$6
nSplit=$7


echo "----------------- stage=" $stage "=============="

if [ $stage -le 0 ]; then
	echo "feature prep"
	x=$traindir
	 steps/make_fbank_pitch.sh --nj $nSplit --cmd "$train_cmd --max-jobs-run 10" $x{,/log,/data}
	      steps/compute_cmvn_stats.sh $x $x/log $x/data
	utils/fix_data_dir.sh $x

fi



#=============================================================

if [ $stage -le 1 ]; then
	  mkdir -p $exp/mono;
	  steps/train_mono.sh --nj $nSplit --cmd "$train_cmd" \
	    $traindir $langdir $exp/mono
	   graph_dir=$exp/mono/graph
	  mkdir -p $exp/mono_ali
	  steps/align_si.sh --nj $nSplit --cmd "$train_cmd" \
	    $traindir $langdir $exp/mono $exp/mono_ali
	  mkdir -p $exp/tri1
	  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" $NUMLEAVES $NUMGAUSSIANS \
	    $traindir $langdir $exp/mono_ali $exp/tri1
	  mkdir -p $exp/tri1_ali
	  steps/align_si.sh --nj $nSplit --cmd "$train_cmd" \
	    $traindir $langdir $exp/tri1 $exp/tri1_ali
	  mkdir -p $exp/tri2b
	  steps/train_lda_mllt.sh --cmd "$train_cmd" \
	    --splice-opts "--left-context=3 --right-context=3" $NUMLEAVES $NUMGAUSSIANS \
	    $traindir $langdir $exp/tri1_ali $exp/tri2b
	  mkdir -p $exp/tri2b_ali
	  steps/align_si.sh --nj $nSplit --cmd "$train_cmd" --use-graphs true \
	    $traindir $langdir $exp/tri2b $exp/tri2b_ali
	  steps/train_sat.sh --cmd "$train_cmd" $NUMLEAVES $NUMGAUSSIANS \
	    $traindir $langdir $exp/tri2b $exp/tri3b
	  mkdir -p $exp/tri3b_ali
	steps/align_fmllr.sh --nj $nSplit --cmd "$train_cmd" \
  	$traindir $langdir $exp/tri3b $exp/tri3b_ali
fi

