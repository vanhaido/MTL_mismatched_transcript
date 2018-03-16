#!/bin/bash

./path.sh

ROOT=/home/hai/projects/ws15-pt-data
DATA=$ROOT/data
#phone_set=/home/hai/projects/ws15-pt-data/data/phonesets/univ.compact.txt
phone_set=$DATA/let2phn/pinyin_output.vocab

lm_dir=$DATA/transcripts/mismatched/vietnamese/mandarin/no_oov/lm
lm=$lm_dir/bigram.lm
lm_fst=$lm_dir/bigram.fst
raw_text=$DATA/transcripts/mismatched/vietnamese/mandarin/no_oov/1_phone.txt
raw_text_test=$DATA/transcripts/mismatched/vietnamese/mandarin/no_oov/1_phone.txt
text=$lm_dir/1_phone_text.txt
text_test=$lm_dir/1_phone_text.txt

mkdir $lm_dir

cat $raw_text | awk '{for(i=2;i<=NF;i++) {printf(" ");printf($i);} printf("\n")}' | sed -e 's/://' > $text


ngram-count -order 2 -text $text -lm $lm
ngram -order 2 -lm $lm -ppl $text_test  -unk

echo "done "




egrep -v '<s> <s>|</s> <s>|</s> </s>' $lm | \
    arpa2fst - | fstprint | \
    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$phone_set --osymbols=$phone_set  --keep_isymbols=false --keep_osymbols=false | \
    fstrmepsilon | fstarcsort --sort_type=ilabel > $lm_fst

echo "done generating FST"
echo $lm_fst


