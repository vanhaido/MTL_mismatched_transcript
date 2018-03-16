#!/bin/bash
. ./cmd.sh
. ./path.sh

nnet=$1/tri5_uc-mlp-part2/
srcdata=$2	
bn_data=$3	
nj=$4


steps/nnet/make_bn_feats.sh --cmd "$train_cmd" --nj $nj $bn_data $srcdata $nnet $bn_data/_log $bn_data/_data
steps/compute_cmvn_stats.sh $bn_data $bn_data/_log $bn_data/_data
