#!/usr/bin/perl

$fndict="/home/hai/Dropbox/ADSC/Dict/Vietnamese/wenda/lexicon.txt";
$fndict2="/home/hai/Dropbox/ADSC/Dict/Vietnamese/wenda/lexicon_norm.txt";
$fndict3="/home/hai/Dropbox/ADSC/Dict/Vietnamese/wenda/lexicon_norm_notone.txt";
$fndict4="/home/hai/Dropbox/ADSC/Dict/Vietnamese/wenda/lexicon_norm_notone_IPA.txt";
$fnphone2ipa="/home/hai/Dropbox/ADSC/Dict/Vietnamese/sampa2ipa/vietnamese_sampa2ipa.txt";

#$fndict4="/home/hai/Dropbox/ADSC/Dict/Vietnamese/wenda/lexicon_norm_notone_monothong.txt";
#$fnphone2ipa="/home/hai/Dropbox/ADSC/Dict/Vietnamese/sampa2ipa/vietnamese_sampa2monothong.txt";

open(fdict, $fndict);
open(fdict2, ">$fndict2");
open(fdict3, ">$fndict3");
open(fdict4, ">$fndict4");

open(fphone2ipa, $fnphone2ipa);





#============================
@lines=<fphone2ipa>;
foreach $l(@lines)
{
#	printf("*** $l");
	@word=split(/\t/,$l);
	chomp($word[1]);
	#printf("$word[0]=$word[1]\n");
	$hash_phone2ipa{$word[0]} = $word[1];
}

#print ($hash_phone2ipa{"uI@"}."\n");

#---------------------------------

#exit ;

@lines=<fdict>;
foreach $l(@lines)
{
    if ($l=~"\t")	
	{
	@word=split(/\t/,$l);
	$word[1]=~ s/\#//g;
	$word[1]=~ s/\.//g;
	$word[1]=~ s/^\s+|\s+$//g;
	$word[1]=~ s/\s+/ /g;
	print (fdict2 $word[0]."\t".$word[1]."\n");

	#  remove tone marks
	$word[1]=~ s/\_[1-6]//g;
	$word[1]=~ s/^\s+|\s+$//g;
	$word[1]=~ s/\s+/ /g;
	print (fdict3 $word[0]."\t".$word[1]."\n");
	#print ($word[0]."\t".$word[1]."\n");	

	# ------------------
	@phone=split(/ /,$word[1]);
	$ipa="";
	$P="";
	foreach $p(@phone)
	{
		#print($hash_phone2ipa{$p});		
		$P=$P."-".$p;
		$x=$hash_phone2ipa{$p};
		#if ($x eq ""){		
		#	print (fdict4 "$p\n");}
		$ipa=$ipa." ".$hash_phone2ipa{$p};
	}
	#print ($ipa);	
	$ipa=~ s/^\s+|\s+$//g;	
	$hash{$word[0]} = $ipa;
	#print("$word[0]=$word[1]=$P=$ipa\n");
	print (fdict4 $word[0]."\t".$ipa."\n");
	}
}
exit;


@lines=<fword>;
foreach $l(@lines)
{
#	printf("*** $l");
	@word=split(/ /,$l);
	foreach $w(@word)
	{
#		print("*". $w."=".$hash{$w});		
	}
	print("\n");
#	print($hash{$word[0]} = $word[1];
}



#print ("__".$hash{"dsfdsfchính"}."**\n");
