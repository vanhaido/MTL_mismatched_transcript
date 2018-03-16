#!/bin/bash
. ./cmd.sh
. ./path.sh

###
### Now we can build the universal-context bottleneck network
### - Universal context MLP is a hierarchy of two bottleneck neural networks
### - The first network can see a limited range of frames (11 frames)
### - The second network sees concatenation of bottlneck outputs of the first 
###   network, with temporal shifts -10 -5 0 5 10, (in total a range of 31 frames 
###   in the original feature space)
### - This structure has been reported to produce superior performance
###   compared to a network with single bottleneck
### 


traindir=$1 
alignmentdir=$2	
dnndir=$3	







traindnndir=$dnndir/train_dnn
devdnndir=$dnndir/dev_dnn

#kws_make_dev_set.sh $traindir $traindnndir $devdnndir
utils/subset_data_dir_tr_cv.sh $traindir $traindnndir $devdnndir
#HAI/HAI_subset_data_dir_tr_cv.sh $traindir $traindnndir $devdnndir


  # Let's train the first network:
  # - the topology will be 90_1200_1200_80_1200_NSTATES, the bottleneck is linear


	dir=$dnndir/tri5_uc-mlp-part1
	#  ali=$expdir/tri5c_ali
	ali=$alignmentdir
if [ 1 -eq 1 ]; then
  $cuda_cmd $dir/_train_nnet.log \
    steps/nnet/train.sh --hid-layers 2 --hid-dim 1200 --bn-dim 80 --feat-type plain --splice 5 --learn-rate 0.008  \
       $traindnndir $devdnndir data/lang ${ali} ${ali} $dir || exit 1;
fi

  # Compose feature_transform for the next stage 
  # - remaining part of the first network is fixed
  dir=$dnndir/tri5_uc-mlp-part1
  feature_transform=$dir/final.feature_transform.part1
  {
    nnet-concat $dir/final.feature_transform \
      "nnet-copy --remove-last-layers=4 --binary=false $dir/final.nnet - |" \
      "utils/nnet/gen_splice.py --fea-dim=80 --splice=2 --splice-step=5 |" \
      $feature_transform
  }

  # Let's train the second network:
  # - the topology will be 400_1200_1200_30_1200_NSTATES, again, the bottleneck is linear
  { # Train the MLP
  dir=$dnndir/tri5_uc-mlp-part2
  $cuda_cmd $dir/_train_nnet.log \
    steps/nnet/train.sh --hid-layers 2 --hid-dim 1200 --bn-dim 30 --feature-transform $feature_transform --learn-rate 0.008 \
    $traindnndir $devdnndir data/lang ${ali} ${ali} $dir || exit 1;
  }
