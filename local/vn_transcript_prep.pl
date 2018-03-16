#!/usr/bin/perl

$trans_file="/home/hai/projects/ws15-pt-data/data/transcripts/matched/vietnamese/vietnamese_transcription.txt";
$trans_out_dir="/home/hai/projects/ws15-pt-data/data/transcripts/matched/vietnamese/t/";

printf("This script is to extract a single transcription file into many individual files");


open(f, $trans_file);
@lines=<f>;

foreach $l (@lines)
{
@w=split(/:/, $l);
$fname=$trans_out_dir.$w[0].".txt";
open(f,">$fname");
print(f @w[1]);
}

printf("done\n");
