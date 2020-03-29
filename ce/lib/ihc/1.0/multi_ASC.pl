#!/usr/bin/perl -w 

use strict;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/";

my $dir=cwd();
my $integration_tools="$FindBin::Bin";
my $monitor_flag=0;
my %branch_cmd;
our %parameters;
my @branches;
my @top_level_names;
my @branch_command_line;
my $tree_file="";
my $checkports=0;
if ($#ARGV<1){Usage();exit;}


for(my $i=0;$i<=$#ARGV;$i++){
	if ($ARGV[$i] eq "--help") {	
					Usage();
					print "Tags available:\n";
					print "\t--help\t\t\t\t: This help\n";
					exit(1);
					}
	elsif ($ARGV[$i] eq "-monitor"){$monitor_flag=1;}
	elsif ($ARGV[$i] eq "-Tfile"){$tree_file=$ARGV[++$i];}
	elsif ($ARGV[$i] eq "-checkports"){$checkports=1}
	#else { if ($ARGV[$i]=~/^\s*-/){print "Error flag $ARGV[$i]\n";exit(1);}}
	}

# remove files 
if (-e "run_ASC.log"){
	system("rm -f run_ASC.log ; touch run_ASC.log");
	}
if (-e ".##monitor_hash.pl"){
	system("rm -f .##monitor_hash.pl");
	}

open LOG ,">run_ASC.log" or die "cannot open file : $!\n";
print LOG "-" x 50 ."\nmulti_ASC command : $0 @ARGV\n"."-" x 50 ."\n";
print LOG "START TIME ".localtime()."\n";
close (LOG);
# Shifting tree file from the input command
my $module_directory=shift;
$tree_file=($tree_file eq "") ? shift : $tree_file ;

my $command_line;
while (@ARGV){
	$command_line.=" ".shift;
	}
$command_line=~s/-Tfile\s+\S+//;
my $temp=`tail -n 3  $tree_file | grep ")"`;
if ($temp){
	system("echo \"\n\n\" >> $tree_file");
	}
open TREE , "$tree_file" or die "cannot open file $tree_file : $!\n"; # opening the tree project
my $top_level_name;
while(<TREE>){
	if ($_=~/(top_level|top\s*level)\s*:\s*(\w+)/){
		$top_level_name=$2;
		last;
		}
	}
print "Creating sub-trees ... ";
my $original_command_line=$command_line;
$original_command_line=~s/-feedlevel\s+\d+//;
my $last_pos=tree_information("$tree_file",0,0,$original_command_line,$original_command_line,$top_level_name);
print " done !!!\n";
print "START TIME ".localtime()."\n";
for(my $i=0;$i<$#branches;$i++){
	print "RUNNING BOX TOP LEVEL : $top_level_names[$i]\n";
    if ($command_line =~ m/(-be)/i){run_ASC($branches[$i],"$branch_cmd{$top_level_names[$i]} -be",$top_level_names[$i],0,$checkports);} #changed by nizan to support -be ASC flag 
    else {run_ASC($branches[$i],$branch_cmd{$top_level_names[$i]},$top_level_names[$i],0,$checkports);}
	}
print "RUNNING ROOT TREE\n";
system("echo \"ROOT\" >> run_ASC.log");
run_ASC($branches[$#branches],$command_line,"root",1,$checkports);

print "checking parameters ....";
while(1){
	if ($command_line=~s/-PCS\s+(\S+)//){
		if ($1 and (-e $1)){
			require "$1";
			}
		}
	else{last;}
	}
if (-e "PCS_info.pl.used"){
#        open FILE ,">>PCS_info.pl.used" or die "cannot open file PCS_info.pl.used : $!\n";
#	print FILE "1;\n";
#	close(FILE);
#	require "PCS_info.pl.used";
#	system("rm -f PCS_info.pl.used");
	}
my $parameters_string="";
foreach my $key (%parameters){
		foreach my $key2 (%{$parameters{$key}}){
			if ((exists $parameters{$key}{$key2}) and ($parameters{$key}{$key2} ne "used")){
				$parameters_string.="\tinstance $key parameter $key2 value $parameters{$key}{$key2}\n";
				}
			}
		}
if ($parameters_string ne ""){
	my $string="\nThere are unused hash parameters:\n$parameters_string\n";
	open FILE ,">>run_ASC.log" or die "cannot open file run_ASC.log : $!\n";
	print FILE $string;
	close FILE;
	print "check run_ASC.log\n";
	}
else{
	print " ok!!!\n";
	}

print "END TIME ".localtime()."\n";
open LOG ,">>run_ASC.log" or die "cannot open file : $!\n";
print LOG "END TIME ".localtime()."\n";
close (LOG);
#-----------
# Function
#-----------

sub Usage{
	print STDOUT "-" x 40 ."\n";
	print STDOUT "This script designed to connect parts of the top level\n";
	print STDOUT "separately with the ASC.pl script.\n";
	print STDOUT "-" x 40 ."\n";
	print STDOUT "Usage : $0 <module directory> <full path to top tree file> <additional flags for the ASC.pl scripts> \n";
	run_ASC_command("--help");
	print STDOUT "-" x 40 ."\n";
	print STDOUT "For help print $0 --help\n";
	}

sub tree_information{
	my ($tree_file,$counter,$top_level_num,$command_line_ASC,$orig_cmd_line,$top_level_name)=@_;
	my $global_tree="";
	my $flag=0;
	my $branch="";
	my $level_num;
	my $level_name;
	my $position;
	$branch.="top_level : $top_level_name\n";
	while (<TREE>){ # while the project tree file 
		$_=~s/#.*//; # remove comments
#		next unless $_!~/^\s*$/; # remove blank line
		if ($_=~/(\d+)\)\s*(\w+)\s*(.*)/){
			$level_num=$1;
			$level_name=$2;
			}
		if (($level_num and ($top_level_num>=$level_num)) or eof){
				push(@branches,$branch);
				push(@top_level_names,$top_level_name);
				push(@branch_command_line,$command_line_ASC);
				return $position;
				}
		if ($_=~/(\s*)(\d+)\)\s*(\w+)\s*(.*)\s+-box(.*)\b/){
			if ($5){
				print "\n**Error -- Please make sure -box flag is at the end of the line:\n$_";
				exit(1);
				}
#			print $_;
			my $added_tags=$4;
			my $spaces=$1;
			my $top_level_num2=$2;
			my $top_level_name2=$3;
			$added_tags=~s/-add2cmd.*//;
			$added_tags=~s/-cmd.*//;
			$top_level_name2 =($added_tags=~ /-m\s+(\w+)/) ? $1 : $top_level_name2;
			$branch.="$spaces".($top_level_num2-$top_level_num).") $top_level_name2 $added_tags\n";
			$_=~s/-box//;
			if ($_=~s/-cmd\s+(.*)//){
				$command_line_ASC=$1;
				chomp($command_line_ASC);
				}
			elsif ($_=~s/-add2cmd\s+(.*)//) {
				$command_line_ASC="$orig_cmd_line $1";
				}
			else{
				$command_line_ASC=$orig_cmd_line;
				}
			$branch_cmd{$top_level_name2}=$command_line_ASC;
			my $position=tree_information($tree_file,$counter+1,$top_level_num2,$command_line_ASC,$orig_cmd_line,$top_level_name2);
			if (!defined $position){
				print "Error -- the tree has problems $top_level_name2\n";
				exit(1);
				}
			seek(TREE,$position-1,0);
			next;
			}
		elsif($counter != 0){
			if ($_!~/^\s*$/){
				my $level=$level_num-$top_level_num;
				$_=~s/\d+\)/$level\)/;
				}
			$position=tell(TREE);
			}
			if ($_!~/^\s*$/){
				$branch.=$_;
				}
		}
	}

sub run_ASC_command{
    my ($arg_str)=@_;
    return system("$integration_tools/ASC.pl $arg_str"); 
}

		
sub run_ASC{
	my ($tree,$command_line_ASC,$top_level_name,$root,$checkport)=@_;
	open FILE ,">temp.tree" or die "cannot open temp.tree: $!\n";
	print FILE $tree;
	close (FILE);
	if (!($root)){$command_line_ASC=~s/-tb\s+\w+//g;}
    my $additional_argument = (defined $command_line_ASC) ? "$command_line_ASC -multy" : "-multy";
	my $status=run_ASC_command("$module_directory -Tfile $dir/temp.tree $additional_argument");
	system("rm -f temp.tree");
	if ($status and !$checkport) {
		print "ASC.pl failed with the branch: $top_level_name \n";
		exit(1);
		}
	}
