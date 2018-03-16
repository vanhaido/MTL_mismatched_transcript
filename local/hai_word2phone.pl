#!/usr/bin/perl

#$fndict="/home/hai/Dropbox/ADSC/Dict/Vietnamese/wenda/lexicon_norm_notone_IPA.txt";
#$fnword="/home/hai/DeKALDI/Vietnamese/scripts/data/local/lm/websub_text/webtext";
#$fnphone="/home/hai/DeKALDI/Vietnamese/scripts/data/local/lm/websub_text/webtext_phone";


$fndict="/home/hai/Dropbox/ADSC/Dict/Vietnamese/wenda/lexicon_norm_notone.txt";
$fnword="/home/hai/projects/SBS-mul/data/VN_word_refined/dev/text";
$fnphone="/home/hai/projects/SBS-mul/data/VN_word_refined/dev/text_phone";


open(fdict, $fndict);
open(fword, $fnword);
open(fphone, ">$fnphone");

#============================

@lines=<fdict>;
foreach $l(@lines)
{
#	printf("*** $l");
	@word=split(/\t/,$l);

	#$hash{$word[0]} = $word[1];
	$word[1]=~ s/^\s+|\s+$//g;
	$word[1]=~ s/\s+/ /g;
	$hash{$word[0]} = $word[1];
	#printf("$word[0]\t$word[1]\n");
}




@lines=<fword>;
foreach $l(@lines)
{
	$l=~ s/^\s+|\s+$//g;
	$l=~ s/\s+/ /g;
	@word=split(/ /,$l);
	$p="";
	foreach $w(@word)
	{
		#print("*". $w."=".$hash{$w});		
		$p=$p." ".$hash{$w};
	}
	$p=~ s/^\s+|\s+$//g;
	$p=~ s/\s+/ /g;

	print(fphone "$p\n");
}



