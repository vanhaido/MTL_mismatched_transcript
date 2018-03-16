#!/bin/bash
. ./cmd.sh
. ./path.sh

nnet=$1/tri5_uc-mlp-part2/
srcdata=$2	#/media/lychee_w2/dvh508/KWS13/scripts/data/train
bn_data=$3	#/media/lychee_w2/dvh508/KWS13/scripts/data-bn-flp/train
nj=$4


#nnet=/media/lychee_w2/dvh508/KWS13/viet107/flp/exp_plp/tri5_uc-mlp-part2/
#srcdata=/media/lychee_w2/dvh508/KWS13/scripts/data/train
#bn_data=/media/lychee_w2/dvh508/KWS13/scripts/data-bn-flp/train

steps/nnet/make_bn_feats.sh --cmd "$train_cmd" --nj $nj $bn_data $srcdata $nnet $bn_data/_log $bn_data/_data
steps/compute_cmvn_stats.sh $bn_data $bn_data/_log $bn_data/_data
