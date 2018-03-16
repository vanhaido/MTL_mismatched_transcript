#!/bin/bash

./path.sh

langID=VN
lm_dir=data/$langID/local/lang

lang_dir=data/lang
raw_text=data/$langID/train/text
raw_text_test=data/$langID/eval/text
#raw_text_test=/home/hai/projects/SBS-mul/data/SW/train/text
text=data/$langID/local/lang/text_lm
text_test=data/$langID/local/lang/text_lm_test



mkdir $lm_dir -p
lexicon=data/$langID/local/dict/lexicon_nosil.txt
#lexicon=data/AR_CA_HG_MD_UR/local/dict/lexicon_nosil.txt
wlist=$lm_dir/wlist.txt 
cat $lexicon | awk '{print $1}' > $wlist
#wlist=/home/hai/projects/SBS-mul/data/AR_CA_HG_MD_UR/lang/phones/nonsilence.txt




# processing text, remove the first field
#cat $raw_text | awk '{for(i=2;i<=NF;i++) {print $i}}'
if [ 1 -eq 1 ]; then
	echo use text from training transcription
	cat $raw_text | awk '{for(i=2;i<=NF;i++) {printf(" ");printf($i);} printf("\n")}' > $text
else	
	echo use text from web 400MB
	#./local/hai_word2phone.pl # convert webtext in words into IPA phones
	text=/home/hai/DeKALDI/Vietnamese/scripts/data/local/lm/websub_text/webtext_phone
fi

#text=/home/hai/projects/SBS-mul/data/VN/local/lang/text_lm_equal
#text=/home/hai/projects/SBS-mul/data/SW/local/lang/text_50_equal

cat $raw_text_test | awk '{for(i=2;i<=NF;i++) {printf(" ");printf($i);} printf("\n")}' > $text_test

ngram-count -order 1 -text $text -lm $lm_dir/bigram.lm

#ngram-count -vocab $wlist  -order 3  -text $text  -lm $lm  -interpolate1 -interpolate2 -interpolate3  -kndiscount1  -kndiscount2  -kndiscount3

#wlist=/data2/dvh508/hub4/data/local/dict/lexicon_wlist.txt
#wlist=./PM_Lee123.vocab
#tool_dir=/data4/srilm_tool/srilm/bin/i686-ubuntu

#text=/home/hai/projects/SBS-mul/data/VN/local/lang/text_lm_equal
ngram-count -vocab $wlist  -order 1  -text $text -write $lm_dir/bigram_old.count -unk
#ngram-count -order 2 -vocab $wlist -read $lm_dir/bigram.count -lm $lm_dir/bigram.lm -unk -kndiscount -interpolate
ngram-count -order 1 -vocab $wlist -read $lm_dir/bigram_old.count -lm $lm_dir/bigram_old.lm -unk -interpolate

echo "LM for old method"
ngram -order 1 -lm $lm_dir/bigram_old.lm -ppl $text_test  -unk
echo "Simple LM for new method"
ngram -order 1 -lm $lm_dir/bigram.lm -ppl $text_test  -unk

echo "done!"
echo $lm_dir/bigram.lm
exit 1;

 cat $lm_dir/lm.lm | utils/find_arpa_oovs.pl $lang_dir/words.txt  > $lang_dir/oovs.txt
  # grep -v '<s> <s>' because the LM seems to have some strange and useless
  # stuff in it with multiple <s>'s in the history.  Encountered some other similar
  # things in a LM from Geoff.  Removing all "illegal" combinations of <s> and </s>,
  # which are supposed to occur only at being/end of utt.  These can cause 
  # determinization failures of CLG [ends up being epsilon cycles].
#  gunzip -c $lmdir/lm_${lm_suffix}.arpa.gz | \
   cat $lm_dir/lm.lm | grep -v '<s> <s>' | \
    grep -v '</s> <s>' | \
    grep -v '</s> </s>' | \
    arpa2fst - | fstprint | \
utils/remove_oovs.pl $lang_dir/oovs.txt | \
    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$lang_dir/words.txt \
      --osymbols=$lang_dir/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     fstrmepsilon > $lang_dir/G.fst
  fstisstochastic $lang_dir/G.fst
echo "done"




