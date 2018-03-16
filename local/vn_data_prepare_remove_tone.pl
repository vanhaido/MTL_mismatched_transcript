#!/usr/bin/perl
#$fntrans="data/VN/train/text";
#$fng2p="/home/hai/projects/ws15-pt-data/data/tkekona/vietnamese/data/g2p_dict_no_tone.txt";
#$fng2p="/home/hai/projects/ws15-pt-data/data/tkekona/vietnamese/data/g2p_dict.txt";
#$fntrans2="data/VN/train/text2";



$fntrans=$ARGV[0];
$fng2p="/home/hai/projects/ws15-pt-data/data/tkekona/vietnamese/data/g2p_dict_no_tone.txt";
#$fng2p="/home/hai/projects/ws15-pt-data/data/tkekona/vietnamese/data/g2p_dict.txt";
$fntrans2=$ARGV[1];


printf ("process to remove tones\n");
printf($fntrans);

#---------
open(ftrans, $fntrans);
open(fg2p, $fng2p);
open(ftrans2, ">$fntrans2");


my %hash;
while (<fg2p>)
{
   chomp;
   my ($key, $val) = split /\t/;
   $hash{$key} .= exists $hash{$key} ? "$val" : $val;
}

@trans=<ftrans>;

foreach $tran (@trans){
	@utt_name=split(/\t/, $tran);
	$tran2=$utt_name[0]."\t";
	chomp($utt_name[1]);
	@phones=split(/ /,$utt_name[1]);
	$first=1;
	foreach $phone (@phones){
	 $phone2=$hash{$phone};
	if ($first==1){
	 $tran2=$tran2.$phone2;
	 $first=0;}
	else
	 {$tran2=$tran2." ". $phone2;}
	}
print(ftrans2 $tran2."\n");
}

close ftrans;
close fg2p;
close ftrans2;

