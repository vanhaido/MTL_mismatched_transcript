#!/bin/bash -u

# Generating a phone bigram LM



. ./path.sh

echo "Preparing the language model G acceptor"



if [ 1 -eq 0 ]; then
	cp -r data/lang/* $test

	fstprint --isymbols=data/lang_test/phones.txt --osymbols=data/lang_test/words.txt \
	  data/lang_test/L.fst \
	  | LC_ALL=en_US.UTF-8 local/project_phones.py data/${LCODE}/lang_test/phones.txt \
	  | fstcompile --isymbols=data/lang_test/phones.txt --osymbols=data/lang_test/words.txt \
	  > $test/L.fst

	fstprint --isymbols=data/lang_test/phones.txt --osymbols=data/lang_test/words.txt \
	  data/lang_test/L_disambig.fst \
	  | LC_ALL=en_US.UTF-8 local/project_phones.py data/${LCODE}/lang_test/phones.txt \
	  | fstcompile --isymbols=data/lang_test/phones.txt --osymbols=data/lang_test/words.txt \
	  > $test/L_disambig.fst

fi 
#exit 1;

#cat $TEXT_PHONE_LM/${LCODE}/bigram.lm | \


lm_arpa=/media/hai/HD/projects/SBS-mul_generate_list/data/VN/local/lm/lm_phone.arpa
lm_fst=/media/hai/HD/projects/SBS-mul_generate_list/data/VN/local/lm/bigram.fst
#phone_set=/home/hai/projects/ws15-pt-data/data/phonesets/univ.compact.txt
phone_set=/home/hai/Dropbox/ADSC/code/BUT_phone_recognizer/BABEL/phone_set.txt

#lm_arpa=/home/hai/projects/ws15-pt-data/data/phnlms/swahili/sw_wiki_2.lm
#lm_fst=/home/hai/projects/ws15-pt-data/data/phnlms/swahili/bigram.fst


egrep -v '<s> <s>|</s> <s>|</s> </s>' $lm_arpa | \
    arpa2fst - | fstprint | \
    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$phone_set --osymbols=$phone_set  --keep_isymbols=false --keep_osymbols=false | \
    fstrmepsilon | fstarcsort --sort_type=ilabel > $lm_fst

echo "done"
echo $lm_fst

exit 1;
#=======================================================

cat data/${LCODE}/local/lang/bigram.lm | \
  sed 's/\tg/\tɡ/g' | sed 's/ g/ ɡ/g' | \
  sed 's/sil/!SIL/g' | \
  egrep -v '<s> <s>|</s> <s>|</s> </s>' | \
  arpa2fst - | fstprint | \
  utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=/home/hai/projects/ws15-pt-data/data/phonesets/univ.compact.txt \
    --osymbols=/home/hai/projects/ws15-pt-data/data/phonesets/univ.compact.txt  --keep_isymbols=false --keep_osymbols=false | \
  fstrmepsilon | fstarcsort --sort_type=ilabel > $test/G_for_PT.fst


 
# fstisstochastic $test/G.fst
# The output is like:
# 9.14233e-05 -0.259833
# we do expect the first of these 2 numbers to be close to zero (the second is
# nonzero because the backoff weights make the states sum to >1).
# Because of the <s> fiasco for these particular LMs, the first number is not
# as close to zero as it could be.

#local/validate_lang.pl $test || exit 1

echo "Done preparing G for PT."
