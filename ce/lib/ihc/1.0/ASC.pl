#!/usr/bin/perl -w 
#################################################################################################
#use strict;
use POSIX;
use File::stat;
#use Cwd;
$|=1;
if (!@ARGV){
	Usage();
	}

## global variables 
our %connect;
our %special_port_names = (EMPTY => 1);
our %split = %special_port_names;
our %wireprefix;
our %parameters;
our %ext_inout;
our $leaf_files="";
our %constant;
our %monitor_module_string;
our %drive;
our %port_size;
our %hash_port;
our %connect2;
our %import_sv;
our %ASCprefix;
# file name
our $tree_file="project.tree";
my $esig_file="extern.sig";
my $PCS_info=0;
my @PCS_info_file;
my $connectivity_log="connectivity.log";
my $ASC_file=".##input_output.log";
my $tb_driver_txt="";
my $monitor_file=".##monitor_hash.pl";
my $str_reg="reg";
# define variables
my %tree;
my $last_number=0;
my @last_module;
my $file_name;
my $file_overwrite=0;
my $file_flag=1;
my %number_of_module_times;
my $auto_top=1;
my $tb=0;
my $B2b=0;
my $v1995=0;
my @LS;
my $rmd;
my @packages;
my $owtb=0;
my $mtl_globals="MTL_globals_BE";
my $links=0;
my $emptytb=0;
my $module_library=$ARGV[0]; # here you enter the module lib
my $add_library=$module_library;
my $exclude_library="";
my $counter=0;
my %vhdl_interface_end;
my $warning=0;
my $tb_name="";
my %generate_counter;
my $create_monitor_file_flag=0;
my $multy=0;
my $add2instance_name=0;
my $vmm=0;
my @inout_file;
my @esig_array=();
my %inout_hash;
my %inout_hash_port;
my $mem_type="file";
my $timescale="";
my $tbtimescale="";
my $connectivity_flag=0;
my $changes=0;
my %port_hash;
my %find;
my %replace;
my $print2dir;
my $checkports=0;
my %feed_through;
my %mismatch;
my $feedlevel=2;
my $ASCfiles=0;
my $noezfeed=0;
my $grbg=0;
my %top_level_name;
my @NOFLAGS;
my $checkPCS=0;
my $stub_out_def = undef;
my @suffix_array = qw(.v .sv .vhd);
my @extension_array = qw(_struct _behavioral .release);
#-------------------------------------------------------------------------
#----------------- getting command line parameter ------------------------
#-------------------------------------------------------------------------

if ((-d $ARGV[0]) or ($ARGV[0] eq "--help")) {}
elsif($ARGV[0] eq "-PCSU"){connectivity_usage();}
elsif($ARGV[0] eq "-TfileU"){tree_usage();}
else{Usage();}

for(my $i=0;$i<=$#ARGV;$i++){
	if ($ARGV[$i] eq "-no_auto_top") {$auto_top=0;}
	elsif ($ARGV[$i] eq "-B2b") {$B2b=1;}
	elsif ($ARGV[$i] eq "-tb") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "tb name illegal\n";
													exit(1);}
													$tb_name=$ARGV[$i+1];$tb=1;}
	elsif ($ARGV[$i] eq "-v1995") {$v1995=1;}
	elsif ($ARGV[$i] eq "-ASCfiles") {$ASCfiles=1;}
	elsif ($ARGV[$i] eq "-changes") {$changes=1;}
	elsif ($ARGV[$i] eq "-links") {$links=1;}
	elsif ($ARGV[$i] eq "-noezfeed") {$noezfeed=1;}
	elsif ($ARGV[$i] eq "-hash") {$mem_type="hash";}
	elsif ($ARGV[$i] eq "-checkports") {$checkports=1;}
	elsif ($ARGV[$i] eq "-Tfile") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "Tree file name illegal\n";
													exit(1);}
											 		$tree_file=$ARGV[$i+1];}
	elsif ($ARGV[$i] eq "-print2dir") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "Tree file name illegal\n";
													exit(1);}
											 		$print2dir=$ARGV[$i+1];}
	elsif ($ARGV[$i] eq "-addext") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "suffix illegal\n";
													exit(1);}
											 		push (@extension_array,$ARGV[$i+1]);}
	elsif ($ARGV[$i] eq "-tbd") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "Test bench driver file illegal\n";
													exit(1);}
											 		$tb_driver_txt=$ARGV[$i+1];}
	elsif ($ARGV[$i] eq "-timescale") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "timescale illegal\n";
													exit(1);}
											 		$timescale=$ARGV[$i+1];
											 		$tbtimescale=($tbtimescale eq "") ? $timescale : $tbtimescale;}
	elsif ($ARGV[$i] eq "-tbtimescale") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "tbtimescale illegal\n";
													exit(1);}
											 		$tbtimescale=$ARGV[$i+1];}
	elsif ($ARGV[$i] eq "-feedlevel") {if ($ARGV[$i+1]=~/^\s*-/){
													print "feedlevel illegal\n";
													exit(1);}
											 		$feedlevel=$ARGV[$i+1];}
	elsif ($ARGV[$i] eq "-Esig") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "External signals file name illegal\n";
													exit(1);}
											 		$esig_file=$ARGV[$i+1];}
	elsif ($ARGV[$i] eq "-package") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "package file name illegal\n";
													exit(1);}
											 		push(@packages,$ARGV[$i+1]);}
	elsif ($ARGV[$i] eq "-addlib") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "Dir name illegal\n";
													exit(1);} 
											 		$add_library.=" $ARGV[$i+1]";
													if (!(-d $ARGV[$i+1])){
														print "No such directory $ARGV[$i+1].\n";
														exit(1);}}
	elsif ($ARGV[$i] eq "-exclib") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "Dir name illegal\n";
													exit(1);} 
											 		$exclude_library.=" ! -path \"$ARGV[$i+1]*\"";
													if (!(-d $ARGV[$i+1])){
														print "No such directory $ARGV[$i+1].\n";
														exit(1);}}
	elsif ($ARGV[$i] eq "-PCS") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "PCS_info file name illegal\n";
													exit(1);}
											 		push(@PCS_info_file,$ARGV[$i+1]);$PCS_info=1;}
	elsif ($ARGV[$i] eq "-CLfile") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "connectivity.log file name illegal\n";
													exit(1);}
											 		$connectivity_log=$ARGV[$i+1];}
	elsif ($ARGV[$i] eq "-LS") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "module name illegal\n";
									 				exit(1);}
													push(@LS,$ARGV[$i+1])}
	elsif ($ARGV[$i] eq "-noflag") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "flag name illegal\n";
									 				exit(1);}
													push(@NOFLAGS,$ARGV[$i+1])}
	elsif ($ARGV[$i] eq "-rmd") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "Directory name illegal\n";
												 	exit(1);}
													$rmd=$ARGV[$i+1]}
	elsif ($ARGV[$i] eq "-stub_out") {if (!$ARGV[$i+1] or $ARGV[$i+1]=~/^\s*-/){
													print "Stub out name illegal\n";
												 	exit(1);}
													$stub_out_def=$ARGV[$i+1]}
	elsif ($ARGV[$i] eq "-ow") {$file_overwrite=3;}
	elsif ($ARGV[$i] eq "-checkPCS") {$checkPCS=1;}
	elsif ($ARGV[$i] eq "-grbg") {$grbg=1;}
	elsif ($ARGV[$i] eq "-connectivity") {$connectivity_flag=1;}
	elsif ($ARGV[$i] eq "-multy") {$multy=1;}
	elsif ($ARGV[$i] eq "-add_uniq") {$add2instance_name=1;}
	elsif ($ARGV[$i] eq "-vmm") {$vmm=1;}
	elsif ($ARGV[$i] eq "-notbreg") {$str_reg="";}
	elsif ($ARGV[$i] eq "-monitor") {$create_monitor_file_flag=1;}
	elsif ($ARGV[$i] eq "-owtb") {$owtb=1;}
	elsif ($ARGV[$i] eq "-emptytb") {$emptytb=1;}
	elsif ($ARGV[$i] eq "-~owtb") {$owtb=2;}
    elsif ($ARGV[$i] eq "-be") {$mtl_globals="MTL_globals_FE | grep -v ilkn_gbx";}

	elsif ($ARGV[$i] eq "--help") {	
					print "////////////////////////////////////////////////////////////////////////////////\n";
					print "Automatic signal connector is a script designed to create structs automatically.\n";
					print "Usage : $0 <module_directory> [OPTION]... \n";
					print "////////////////////////////////////////////////////////////////////////////////\n";
					print "Tags available:\n";
					print "        -tb <tb name>                    : create test bench in addition to the design structs\n";
					print "        -ow                              : overwrite existing files\n";
					print "        -checkPCS                        : overwrite existing files\n";
					print "        -grbg                            : include grbg modules (-grbg)\n";
					print "        -addext <ext>                    : add new extension to the file (default _struct _behavioral with files .v .sv .vhd)\n";
					print "        -emptytb                         : do not copy the content of the test bench driver to the new file\n";
					print "        -owtb                            : overwrite test bench driver file\n";
					print "        -~owtb                           : not overwrite test bench driver file\n";
					print "        -B2b                             : spread all interface bus to single ports (cannot be use with -tb flag)\n";
					print "        -timescale <timescale>           : add timescale to the head of the struct\n";
					print "        -feedlevel <feed level number>   : ezfeed connection level\n";
					print "        -noezfeed                        : disable ezfeed feature\n";
					print "        -tbtimescale <timescale>         : add timescale to the head of the tb_driver struct\n";
					print "        -checkports                      : check all duplicated outputs\n";
					print "        -auto_top                        : takes out to top level all ports that are not connected\n";
					print "        -addlib <dir>                    : add directory to the modules directory\n";
					print "        -print2dir <dir>                 : print all struct to the directory <dir>\n";
					print "        -tbd <file full path>            : change the name of the txt file tb driver (default : tb_driver_<top leve>.txt)\n";
					print "        -add_uniq                        : add to instance name uses -m flag the suffix and prefix\n";
					print "        -Tfile <file full path>          : change the tree file name (default: project.tree)\n";
					print "                                         : for more information about the tree file enter ASC.pl -TfileU\n";
					print "        -Esig <file full path>           : change the External signals file name (default: extern.sig)\n";
					print "        -package <file full path>        : package file name\n";
					print "        -ASCfiles                        : create ASC file and exit\n";
					print "        -PCS <file full path>            : change the PCS file name (default: PCS_info.pl)\n";
					print "        -CLfile <file_name>              : change the file name of the FPGA connectivity log(default: connectivity.log)\n";
					print "        -v1995                           : change the Structs pattern to verilog 1995 (default: verilog 2001)\n";
					print "        -LS <module name>                : create specific struct (must add -rmd flag & full path to tree file)\n";
					print "        -rmd <root module dir>           : release module directory\n";
					print "        -notbreg                         : Do not add reg in the tb driver file\n";
					print "        -PCSU                            : PCS_info .pl file Usage\n";
					print "        -connectivity                    : creates the connectivity log file (FPGA use)\n";
					print "        -backend                         : using BE view, MTL_globals_BE \n";
                    print "        -stub_out <DEF>                  : Stubs out  desing under ifndef <DEF>\n";
					print "        --help                           : this help\n";
					print "For Any Problems : Dror Suliman 668\n";
					exit(1);
					}
	else { if ($ARGV[$i]=~/^\s*-/){print "Error flag $ARGV[$i]\n";exit(1);}}
	}



if (-e $ASC_file){
	system("rm -f $ASC_file");
	}

system("rm -f *.ASC");
#-------------------------------------------------------------------------
#----------------- checking multy option	--------------------------------
#-------------------------------------------------------------------------
my $input_type=">";
if ($multy){
	$input_type=">>";
	}
#-------------------------------------------------------------------------
#----------------- checking connectivity file if exists ------------------
#-------------------------------------------------------------------------
# 
if ($PCS_info==0){
	push(@PCS_info_file,getcwd()."/PCS_info.pl");
	}
foreach my $PCS_info_file (@PCS_info_file){
	if (-e $PCS_info_file){
		print "require PCS_info file $PCS_info_file ... \n";
		require $PCS_info_file;
		}
	elsif ($PCS_info==1){
		print "Error -- there is no such file PCS info : $PCS_info_file \n";
		exit(1);
		}
	}
if ($checkPCS){
  print "Checking PCS info input ...\n";
  my $error_drive_flag=0;
  foreach my $inst (keys %drive){
	  foreach my $port (keys %{$drive{$inst}}){ 
	     if (exists $drive{$inst}{$port}){
			  if ($drive{$inst}{$port}!~/\d+'?\w*/ and $drive{$inst}{$port}!~/^\s*$/){
				  print "Error in \$drive value $inst $port must be \"\" , <number> or <num>'<radix><number>\n";
				  $error_drive_flag=1;
				  }
			  }
        }
	  }
  if ($error_drive_flag) {exit(1);}
  }
#-------------------------------------------------------------------------
#--------------------- checking input paramater --------------------------
#-------------------------------------------------------------------------
#------ checking if test bench and bus 2 bit flags or on together --------
if ($tb and $B2b){
	print "Cannot use both flags -B2b and -tb!!!\n";
	exit(1);
	}
open LOG , "$input_type"."run_ASC.log" or die "cannot open file run_ASC.log : $!\n"; # opening the tree project
print LOG "-" x 100 ."\nASC command : $0 @ARGV\n"."-" x 100 ."\n";
#------ checking if test bench and bus 2 bit flags or on together --------
if (@LS and !$rmd){
	print "must enter release module directory with flag -rmd\n";
	exit(1);
	}
#------------ if auto_top is on ignoring external signal file ------------
my $esig_exists_flag=0;
if (!(-e $esig_file)) {
	if ($auto_top==1){
		$esig_file="";
		}
	else{	print2log("$esig_file does not exists","warning");
		}
	}
else{
   $esig_exists_flag=1;
	if ($auto_top==1) {
		print2log("$esig_file exists and entered to the input information","warning");
		} 
	open ESIG ,$esig_file or die "cannot open $esig_file : $!\n";
	while(<ESIG>){
		chomp($_);
		push(@esig_array,"$esig_file: $_");
		}
	close(ESIG);
	}

#------------------------------ checking local struct --------------------
if (@LS){
	if ($module_library!~/^\s*\/home/){
		$module_library=cwd()."/$module_library";
		}
  if (-d $rmd){
	  chdir "$rmd";
	  }
  else{
	  print "$rmd directory does not exists\n";
	  exit(1);
	  }
	}

#------------------------------ vladimir file  ---------------------------
open CONNECT , "$input_type$connectivity_log" or die "cannot open file $connectivity_log : $!\n";
#------------------------- end of vladimir file  -------------------------
#------------------- if multy check parameter ----------------------------
if ($multy){
	open USED_CONNECT , "$input_type"."PCS_info.pl.used" or die "cannot open file 3 PCS_info.pl.used : $!\n";
	print USED_CONNECT "#!/usr/bin/perl -w\n";
	}
#------------------- if multy check parameter ----------------------------

#--------------- checking the package file for constant use --------------
foreach my $package (@packages){
	constant_info($package);
	}

#--------------- checking the print2dir directory --------------
if (defined $print2dir){
	chomp ($print2dir);
	if (!(-d $print2dir)){
		print "**Error -- there is no such print2dir directory $print2dir\n";
		exit(1);
		}
	my $result=`find $add_library -type d | grep "\/$print2dir\\b"`;
	if (!($result)){ 
		$add_library.=" $print2dir";
		}
	}
else{
	$print2dir=$module_library;
	}

# getting all files to an array
my @file_name_non_uniq;
foreach my $suffix (@suffix_array) {
   push(@file_name_non_uniq,`find $add_library -type f $exclude_library -name "*$suffix" | grep -v $mtl_globals`);
   if ($links){
      push(@file_name_non_uniq,`find $add_library -type l $exclude_library -name "*$suffix" | grep -v $mtl_globals`);
      }
}
# generating uniq file name array
my %seen = ();
my @file_name = grep { ! $seen{ $_ }++ } @file_name_non_uniq;
#--------------- getting the information from the tree file --------------
my $top_level = tree_information($tree_file);#exit;
#--------------- getting the external signals from PCS  --------------
my $auto_extern_sig = "";
if (exists $ext_inout{$top_level}){
 foreach my $port (keys %{$ext_inout{$top_level}}){
    if (exists $ext_inout{$top_level}{$port}){
	    if ($mem_type eq "hash"){
		 push(@esig_array,"auto_extern.sig: $ext_inout{$top_level}{$port} $port");		
		 }
	 else{
	    $auto_extern_sig .=" $ext_inout{$top_level}{$port} $port\n";
		 }
	 }
   }
 }
	
if ($auto_extern_sig ne ""){
   my $esig_exists_string = "";
   print "Activating auto external signals\n";
   if ($esig_exists_flag){
	   $esig_exists_string=`cat $esig_file`;
	}
	open FILE ,">auto_extern.sig" or die "cannot open file auto_extern.sig : $!\n";
	print FILE $auto_extern_sig.$esig_exists_string;
	close(FILE);
	$esig_file = "auto_extern.sig";
	}
if ($ASCfiles){exit(0);}
if ($checkports){
	foreach my $keys (keys %hash_port){
		if ($hash_port{$keys}>1){
			print LOG "there are  $hash_port{$keys} outputs $keys\n";
			print_port_output_results($keys);
			}
		}
	exit(0);
	}

#------------------------ creating the struct files ----------------------
for(my $i=$#last_module ; $i>0 ; $i--){ #for all levels 
	# for each of the structs
	foreach my $key (keys %{$tree{$i-1}}){ 
		if ($rmd){
			if (@LS){ # checking if the local struct is in the list listed by user
				my $res=my_grep2($key,\@LS);
				splice_array($res,\@LS)
				}else	{ exit;}
			}
		$changes=check_modification($changes,$print2dir,$key,$tree{$i-1}{$key});
		if (!$changes){
			create_struct($key,\%tree,$module_library,$add_library,$i-1,\$file_overwrite,\%number_of_module_times);
			}
		$counter--;
		if ($counter>0){
			print "$counter struct(s) left ...\r";
			}
		}
	foreach my $key (keys %{$tree{$i-1}}){
		my $file_name=$key."_struct.v";
		remove_port_inout_file_by_instance_ASC($key,$tree{$i-1}{$key});
		my $top_level_temp= (exists $top_level_name{$key}) ? $top_level_name{$key} : "no";
	   create_ASC_file($top_level_name{$key},$key,"$print2dir/$file_name",$key,\%parameters,$find{$key},$replace{$key},"","","","","",($mem_type eq "hash"),0,"nodef");	
		}
	}
system("rm -f $tree{top_level}.ASC");
if ($multy){
	print USED_CONNECT "\n1; # closing the file\n";
	close(USED_CONNECT);
	}
exit(0);
if ($warning){
	print "Found Warnings --> check out run_ASC.log\n";
	}

if (-e $ASC_file){
	system("rm -f $ASC_file");
	}
#----------------------------------------------------------------------------------------
# This function gathers the tree information from the tree file 		    	
#----------------------------------------------------------------------------------------

sub tree_information{
	#--------------------------------------------------------------------------------------------
	# the algorithm of the project tree file: 
	# running through the tree file and saving the module if the next module level is lower or 
	# the same then the module is a leaf.
	#--------------------------------------------------------------------------------------------
	my ($tree_file)=@_;
	$counter=1;
	open TREE , "$tree_file" or die "cannot open file $tree_file : $!\n"; # opening the tree project
	#----------------------------------------------------------------------------------------
	#----------------- creating hash tree for the project tree file -------------------------
	#----------------------------------------------------------------------------------------
	my $top_level_flag=0; # flag 
	my $module_file_name="";
	my $last_module="";
	my $define="nodef";
	my $top_level;
	my @file_lines=get_ASC_tree_file($tree_file,$grbg);
	for (my $ind=0;$ind<=$#file_lines;$ind++){ # while the project tree file 
		my $leaf_flag=0;
  		$define="nodef";
		if (($file_lines[$ind]=~/top level\s*:\s*(\w+)/i) or ($file_lines[$ind]=~/top_level\s*:\s*(\w+)/i)){ # looking for the definition of the top level in the project.tree
			$top_level=$1; # getting the top level
			#------------------------------------------------------------------------------------------
			# if we need to create a test bench it shift the tree one level up.
			#------------------------------------------------------------------------------------------
			if ($tb){ # if it is a test bench 
				$last_module[1]=$top_level; 
				$last_module[0]=$tb_name;
			   $top_level_name{$tb_name}="last";
			   $top_level_name{"tb_driver_$tb_name"}="test_bench";
				@{$tree{0}{"$last_module[0]"}}=($last_module[1],"tb_driver_$last_module[1]");
				$number_of_module_times{$last_module[1]}=1;
				$number_of_module_times{"tb_driver_$last_module[1]"}=1;
				}
			else{
				$last_module[0]=$top_level;
				}
			$tree{"top_level"}=$top_level;
			$top_level_name{$top_level}="test_bench";
			$top_level_flag=1; # light the top level flag
			}
		my $module_name="";
		if ($file_lines[$ind]=~/-m\s+(\w+)/){$module_name=$1;}
		if ($file_lines[$ind]=~/(\d+)\)\s*(\w+)\s*\(*(\d*)\)*\s*\(*(\w*)\)*\s*(-*.*)/){ # lines from the tree
				my $next_number=($ind != $#file_lines) ? get_ASC_next_number($file_lines[$ind+1]) : 0; 
				my $level=$1;
				my $module=$2;
			   if ($module_name eq ""){$module_name=$module;}
				my $module_file_name=file_name_processor_ASC($module_name,\@file_name,($mem_type eq "hash")); 
				my $iteration_number=1;
				if ($3){
					$iteration_number=$3;
					}
				my $text_pre="";
				if ($4){
					$text_pre=$4;
					}
				if ($module=~/(struct|behavioral)\.*v*/){print "** Error -- Please remove all _struct and _behavioral from the modules name\n";exit(1);}
				$tree{'offset'}{$module}=0;
				$tree{'offseti'}{$module}=0;
				$tree{'offsetx'}{$module}=0;
				$tree{'putnum'}{$module}=1;
				my $prefix="";
				my $gen=0;
				if ($5){
					my $tree_line=$5;
					$tree_line=~s/-add2cmd.*//;
					$tree_line=~s/-cmd.*//;
					my @tag=split(/\s+/,$tree_line); 
					if (defined $find{$module}){
						delete $find{$module};
						delete $replace{$module};
						}
					if (defined $tree{'define'}{$module}){	
						delete $tree{'define'}{$module};
						}
					for(my $i=0;$i<=$#tag;$i++){
						if ($tag[$i] eq "-pre"){
							$tree{'prefix'}{$module}=$tag[++$i];
							}
						elsif ($tag[$i] eq "-putnum"){
							$tree{'putnum'}{$module}=0;
							$tree{'offset'}{$module}=$tag[++$i];
							$tree{'offsetx'}{$module}=$tag[$i];
							}
						elsif ($tag[$i] eq "-noparam"){
							$tree{'noparam'}{$module}=1;
							}
						elsif ($tag[$i] eq "-f&r"){
							my ($find,$replace);
							($find,$replace)=split(':',$tag[++$i]);
                            #print "\nDBG Yossef : $tag[$i] - $tag[++$i]\n" ;
                     check_variable_definition($find,"if&r instance number");
							push(@{$tree{'find'}{$module}{"no_prefix"}},$find);
							push(@{$tree{'replace'}{$module}{"no_prefix"}},$replace);
							push(@{$find{$module}},$find);
							push(@{$replace{$module}},$replace);
							}
						elsif ($tag[$i] eq "-if&r"){
							my ($find,$replace,$number);
							my $str=$tag[++$i];
							my $first_flag = 1;
							while($str ne ""){
  							  my @array=split(':',$str);
							  $find=($first_flag) ? shift(@array) : $find;
							  $replace=shift(@array);
							  $number=shift(@array);
							  check_variable_definition($number,"find in line $tree_line is");
 							  $str = join(":",@array);
							  my ($start,$end) = ($number =~/-/) ? split('-',$number) : ($number,$number);
							  for(my $index= $start ; $index<=$end ; $index++){
  								push(@{$tree{'find'}{$module}{"no_prefix"}},"$find?$index");
								  push(@{$tree{'replace'}{$module}{"no_prefix"}},$replace);
								  push(@{$find{$module}},"$find?$index");
								  push(@{$replace{$module}},$replace);
							  }
							  $first_flag=0;
							  }
							}
						elsif ($tag[$i] eq "-gen"){
							$gen=1; # generate flag 
							}
						elsif ($tag[$i] eq "-offseti"){
							$tree{'offseti'}{$module}=$tag[++$i]; # offset 
							if ($tag[$i]!~/\d+/){print "enter offset number \n "; exit(1);}
							}
						elsif ($tag[$i] eq "-offset"){
							$tree{'offset'}{$module}=$tag[++$i];
							$tree{'offsetx'}{$module}=$tag[$i]; # offset 
							if ($tag[$i]!~/\d+/){print "enter offset number \n "; exit(1);}
							}
						elsif ($tag[$i]=~/\((\w+)\)/){
							push(@{$tree{'add_prefix'}{$module}{$text_pre}},$level);
							$prefix.="$tag[$i]";
							}
						elsif ($tag[$i] eq "-m"){
							$tree{'instance_module_name'}{$module}=$tag[++$i];
							$module_name=$tag[$i];
							}
						elsif ($tag[$i] eq "-def"){
							$define=$tag[++$i];
							if ($tag[$i]!~/\w+/){print "enter definition name\n "; exit(1);}
							}
						elsif ($tag[$i] eq "-grbg"){
							if (!$grbg){
								print "Error -- grbg line $_ is added -- no grbg mode\n "; exit(1);}
							}
						}
					}
				if ($next_number<=$level){ # entering the leaf files to a vairable
					$leaf_flag=check_file_result($module_name,$module_file_name);
					}
				else{ $counter++ } # counting structs
				$last_module[$level+$tb]=$module; # entering the last module to an array in order to know if it is a
											# leaf or a struct the script must build.
				$last_number=$level+$tb;		# the last level from the same reason as the last module  
				my $iteration=1;		# the number of instantiation of a module
				my $txt_addition="";	# txt addition to the instantiation and ports
				my $inserted_value="";
				my $string="";
				if ($text_pre){	# if exists $4 means that there is an addition to the name of the module
					$txt_addition=$text_pre;
					$string=(!$add2instance_name and exists $tree{'instance_module_name'}{$module}) ? $module : $text_pre."_".$module;
					}
				else{
					$string=$module;	
					}
				if ($gen){
					$tree{'gen'}{$string}=$iteration_number;
					$top_level_name{$string}=$last_module[$last_number-1]; # remember top level for each instance
					push(@{$tree{$level-1+$tb}{$last_module[$last_number-1]}},$string);
					if ($leaf_flag){create_ASC_file($last_module[$last_number-1],$module_name,$module_file_name,$string,\%parameters,,$find{$module},$replace{$module},$txt_addition,$iteration_number,"","",$prefix,($mem_type eq "hash"),$gen,$define,$tree{'noparam'}{$module})};
					}
				elsif ($iteration_number and $iteration_number>$tree{'putnum'}{$module}){	# if exists $3 and it is greater than 1 it means the module must be duplicated
					$iteration=$iteration_number;
					for (my $i=$tree{'offset'}{$module} ; $i<$tree{'offset'}{$module}+$iteration ; $i++){ # the duplication
						my $instance_name=(!$add2instance_name and exists $tree{'instance_module_name'}{$module}) ? "$string" : "$string"."_$i"; # mold is for the NP-5 project 
					   $top_level_name{$instance_name}=$last_module[$last_number-1]; # remember top level for each instance
						push(@{$tree{$level-1+$tb}{$last_module[$last_number-1]}},$instance_name); # opening the instatiation in the tree
  						if ($leaf_flag){create_ASC_file($last_module[$last_number-1],$module_name,$module_file_name,$instance_name,\%parameters,$find{$module},$replace{$module},$txt_addition,$iteration_number,$i,($i+$tree{'offseti'}{$module}),$prefix,($mem_type eq "hash"),$gen,$define,$tree{'noparam'}{$module})};
						}
					}
				else{
					$top_level_name{$string}=$last_module[$last_number-1]; # remember top level for each instance
					push(@{$tree{$level-1+$tb}{$last_module[$last_number-1]}},$string);
  					if ($leaf_flag){create_ASC_file($last_module[$last_number-1],$module_name,$module_file_name,$string,\%parameters,$find{$module},$replace{$module},$txt_addition,$iteration_number,"","",$prefix,($mem_type eq "hash"),$gen,$define,$tree{'noparam'}{$module})};
					}
				# getting the file from the module name
				if ($number_of_module_times{$module}){
					$number_of_module_times{$module}+=$iteration;
					}
				else{
					$number_of_module_times{$module}=$iteration;
					}				
				# get the file name from the module library 
				$module_file_name=file_name_processor_ASC($last_module[$last_number-1],\@file_name,($mem_type eq "hash")); 
				$file_name=$module_file_name;
				$last_module=$module;
				}
			}	
#	check_file_result($module,$module_file_name);
	$file_name=file_name_processor_ASC($last_module[$last_number],\@file_name,($mem_type eq "hash")); 
	close TREE;
	if (!$top_level_flag){ # checking if the top level is defined 
		print2log("No top level defind in the $tree_file\nThe definition must be : TOP LEVEL : <top level name>\n","error");
		}
	return $top_level;
	#------------------------- end of pre processing ----------------------------------
	}	
#############
# Functions #
#############
#-------------------------------------------------------------------------------
# This function gets the struct name and behaveioral modules 						
# gets parameters : 																				
#		$struct_name 								 												
#		$module_library -- the design lib													
#		$tree_ptr -- the pointer to the hash tree											   	 
# 		$level -- the level in the hash tree 												
# 																										   		 
# create struct file																				   		 
#-------------------------------------------------------------------------------
	
sub create_struct{
	my ($struct_name,$tree_ptr,$module_library,$add_library,$level,$file_overwrite_pointer,$number_of_times_ptr)=@_;
	my ($inout_string,$inout_order_string,$wire_string,%ports,%size,@size,@inout,$skipping,%flag_hash,%parameter,$vhdl_generic_flag);
	my ($comment,$reg_string,$module_string,$file_name,$module_list_ptr,@file_name,$parameter_string,$parameter_flag);
	# initialization 
	my %instant_port;
	my %comment_port;
	my $genexists=0;
   my $if_global_flag= 0;
	my $if_string=get_if_str($struct_name);
	$comment=0;$parameter_flag=0;$vhdl_generic_flag=0;
	$reg_string="";$module_string="";$skipping=1;$parameter_string="";
	$module_list_ptr=${$tree_ptr}{$level}{$struct_name};
	my $genvar="i0";
	my $generate_counter=0;
	foreach my $instant (@{$module_list_ptr}){
		if (exists ${$tree_ptr}{'instance_module_name'}{$instant} and (((!-e "$instant.ASC") and ($mem_type ne "hash")) or (($mem_type eq "hash") and (!exists $inout_hash{$instant})))){
		   create_ASC_file($struct_name,${$tree_ptr}{'instance_module_name'}{$instant},"$print2dir/".${$tree_ptr}{'instance_module_name'}{$instant}."_struct.v",$instant,\%parameters,$tree{'find'}{$instant}{"no_prefix"},$tree{'replace'}{$instant}{"no_prefix"},"","","","","",($mem_type eq "hash"),0,"nodef",0);	
			}
		}
	####### going over the modules struct in order to build it 
	foreach my $instant (@{$module_list_ptr}){
		## getting the info from the hash tree 
		my $feed_through_flag=0;
		my $current_module="";
		my $log_max_instant_size=0;
		my ($module,$instantiation,$additional_txt,$iteration_num,$additional_num,$additional_numi,$file_name,$file_name_original,$gen_flag,$if_flag)=tree_info_processor_ASC($instant); # getting the addition from the hash
		if ($gen_flag){
			$genvar=~s/i\d+/i$generate_counter/;
			$generate_counter++;
			}
		if ($if_flag){
			$if_string.="$instant,";
			$if_global_flag=1;
			}
		my $txt_addition_with_no_underscore=$additional_txt;
		$txt_addition_with_no_underscore=~s/_$//;
		if ($txt_addition_with_no_underscore eq ""){
			$txt_addition_with_no_underscore="no_prefix";
			}
		my $additional_num_with_no_underscore=$additional_num;
		$additional_num_with_no_underscore=~s/_//;
		if ($instant ne "tb_driver_$tree{'top_level'}"){
#			$file_name=file_name_processor_ASC($instant,$add_library,0); # getting the module file name
			} else {
#			$file_name=file_name_processor($instant,$add_library,1); # getting the module file name
			}
		if (!(grep(/\b$file_name\b/,@file_name)) or ($additional_num eq "")){
			push(@file_name,$file_name); # saving the files name in order to remove them from the leaf tree
			}
#		open MODULE ,"$instant.ASC" or die "cannot open file $file_name : $!\n";
		if ($additional_num ne ""){
			$log_max_instant_size=ceil(log($iteration_num)/log(2));
			}
		$parameter_string="#(\n";
		my @file_array;
		if ($mem_type eq "hash"){
			@file_array=@{$inout_hash{$instant}};
			}
		else{
#			open MODULE ,"$instant.ASC" or die "cannot open file $file_name : $!\n";
			@file_array=`cat $instant.ASC`;			
			}
		foreach (@file_array){#while (<MODULE>){
			chomp($_);
			if ($_=~/\s*(\binput\b|\boutput\b|\binout\b)\s*(\[*\S*:*\S*\]*)\s*(\w+)\s+(\S*)\s*(\/\/.*)/i){
				my $inout=$1;
				my $size=($2 eq "[:]" or $2 eq "[0:0]") ? "" : $2;
				my $port_=$3;
				my $con_port=$4;
				my $comment=$5;
				chomp($comment);
				my @port;
				my $generate_port=0;
				my $wireprefixstr=(exists $wireprefix{$instant}{$port_}) ? $wireprefix{$instant}{$port_} : "";
                my $width_port;     # Hold the port size
                    $width_port = 1     if ($size eq "");
                    $width_port = $1+1  if ($size =~ /(\d+):\d+/); 
				if ($con_port=~s/=$//){
					$generate_port=1;
					}
				$comment=($comment eq "//") ? "" : $comment;
#				if (exists $feed_through{$port_} and ($inout eq "input") and $level == $feedlevel and (!$noezfeed)){
#					$feed_through_flag=1;
#					$con_port="ezfeed_$con_port";
#					}
				if ($con_port=~s/^\{// and $con_port=~s/\}$//){
					@port=split(/,/,$con_port);
					}
				else{
					push(@port,$con_port);
					}
#				print "$_\n$inout $size $port_ $port\n";
      		    if ($inout eq "output"){									#checking the prefix of the output 
			  		my $prefix=${$tree_ptr}{"prefix"}{$module};
					if ($prefix and $con_port!~/^\s*$prefix/){
					  print "the output $con_port in module $module does not start with the prefix $prefix\n";
					  }
			    }
				if (($port_ eq "instance_num_x") and $additional_num){
					$con_port=$additional_num_with_no_underscore;
					$current_module.="          .$port_($log_max_instant_size\'d$con_port),\n";
					next;
					}
				elsif (exists $drive{$instant}{$port_} or exists $drive{"$struct_name.$instant"}{$port_}){
                    # Check if PCS $drive connect to 0 - then connect the real width of the port
                    if (exists $drive{$instant}{$port_}){
                        if ( $drive{$instant}{$port_} eq "0"){                      
                            $drive{$instant}{$port_} = "$width_port\'b0";
                        }
                    }
                    else{
                        if ( $drive{"$struct_name.$instant"}{$port_} eq "0"){       
                            $drive{"$struct_name.$instant"}{$port_} = "$width_port\'b0";
                        }
                    }
					$current_module.="          .$port_(".((exists $drive{"$struct_name.$instant"}{$port_}) ? $drive{"$struct_name.$instant"}{$port_} : $drive{$instant}{$port_})."),\n";
					if ($inout eq "input" and ((exists $drive{$instant}{$port_} and $drive{$instant}{$port_} eq "") or (exists $drive{"$struct_name.$instant"}{$port_} and $drive{"$struct_name.$instant"}{$port_} eq ""))){
						print LOG "** Warning -- Do not drive input $port_ in instance $instant\n";
						}
					next;
					}
				foreach my $port (@port){
					if ($port=~/'/ or  $port!~/\D+/){next;}
					$port=~s/\[\S+\]//;
					push(@{$ports{$port}{$inout}},"$instant"); # saving all instantiation ports in hash
					push(@{$instant_port{$instant}},"$port");
					$comment_port{$port}="$comment";
					}
#				if ((exists $split{$instant}{$port_}) and ($split{$instant}{$port_} eq "genvar") and ($gen_flag)){
				if ($gen_flag and $generate_port){
					my $gen_msb=$iteration_num-1;
					my $temp_size=$size;
					if ($temp_size=~s/\[(\S+):(\d+)\]/[(($1+1)*$genvar+$1)-:($1+1)]/){
						$gen_msb=($1+1)*$iteration_num-1;
						}
					else{
						$temp_size="[$genvar]";
						}
					if (exists $split{$instant}{$port_}){
						$temp_size=$split{$instant}{$port_};
						}
					$current_module.="          .$port_($wireprefixstr$con_port$temp_size),\n";
					$size{$con_port}="\[$gen_msb:0]";
					}
				elsif ((exists $split{$instant}{$port_}) or (exists $split{"$struct_name.$instant"}{$port_})){
					$current_module.=(exists $split{"$struct_name.$instant"}{$port_}) ? "          .$port_($wireprefixstr$con_port$split{\"$struct_name.$instant\"}{$port_}),\n" : "          .$port_($wireprefixstr$con_port$split{$instant}{$port_}),\n";
					}
				else{
					if (($gen_flag) and ($inout eq "output")){
						print2log("the output $con_port in generated module ".$module." does not end with _x or _s\n","warning");
						}
					$current_module.="          .$port_($wireprefixstr"."{$con_port}" x ($con_port=~/,/) ."$con_port" x ($con_port!~/,/) ."),\n"; 
					}
				if (exists $size{$con_port}){
					$size{$con_port}=check_size($size,$size{$con_port},\%constant);
					}
				else {
					$size{$con_port}=$size;
					}
			#--------------------------------------------------------------------------------
  			#									 Addition for vladimir		
			#--------------------------------------------------------------------------------
			  if (($inout ne "inout") and ($connectivity_flag)){
			  		my $size_v;
			  		if (!$size){$size_v=1;}
					else{$size_v=$size;}
			  		print CONNECT "\$hash{$instant}{$inout}{$con_port}=$size_v;\n";
					}
			#--------------------------------------------------------------------------------
			#									 End addition to vladimir 
			#--------------------------------------------------------------------------------
				}
		elsif ($_=~/\bparameter\b/i){
			my @parameter=split(/,/,$_);
			foreach my $parameter ( @parameter){
				if ($parameter=~/(\w+)\s*=\s*(\S+)/i){
					my $number=$2;
					my $param=$1;
					if ((exists $parameters{$instant}{$param}) or (exists $parameters{"$struct_name.$instant"}{$param})){
						$number=(exists $parameters{"$struct_name.$instant"}{$param}) ? $parameters{"$struct_name.$instant"}{$param} : $parameters{$instant}{$param};
						$parameters{$instant}{$param}="used";
						if ($multy){	
							print USED_CONNECT "\$parameters{\"$instant\"}{\"$param\"}=\"used\";\n"
							}
						}
					$number=fix_var($number);
					$parameter_string.="          .$param($number),\n";
					$parameter{$param}=$number;
					}
				}
			}
		}
		if ($parameter_string=~/\w+/){
				$parameter_string=~s/,\n\s*$/)/;
				}
			else{
				$parameter_string="";
				}
		if (exists ${$tree_ptr}{'gen'}{$instant}){
			$current_module=~s/,$/\n);\nend\nendgenerate\n\n/; # close the module string
			$current_module="genvar $genvar;\ngenerate\n          for($genvar=0;$genvar<${$tree_ptr}{'gen'}{$instant};$genvar=$genvar+1) begin: $instant
         //instantiation of $module\n$module $parameter_string $instant (\n\n".$current_module;
			}
		else {
			my $new_lines="\n\n";
			if (!($current_module=~s/,$/\n);\n\n/)){ # close the module string
				print2log("$module have no input/output !!!\n","warning");
				$current_module=");\n\n";
				$new_lines="";
				}
			$current_module="//instantiation of $module\n$module $parameter_string $instant ($new_lines".$current_module;
			}
		if ($feed_through_flag){
			my @feed_througth_ports=grep(/\bezfeed_/,@{$instant_port{$instant}});
			my @remove_feed_ports;
			my %done;
			foreach my $feed_port (@feed_througth_ports){
				my $temp_feed_port=$feed_port;
				$temp_feed_port=~s/ezfeed_//;
				if (grep(/\b$feed_port\b/,@feed_througth_ports)>=2){
					if (!exists $done{$feed_port}){
						$current_module=~s/\.$temp_feed_port\($feed_port/\.$temp_feed_port\($temp_feed_port/;
						my $res=my_grep2($instant,$ports{$feed_port}{"input"});
						splice_array($res,$ports{$feed_port}{"input"});
						push(@{$ports{$temp_feed_port}{"input"}},"$instant");
						$done{$feed_port}=1;
						push(@remove_feed_ports,$feed_port);
						}
					}
				else{
					change_ezfeed_ASC_file($instant,$temp_feed_port);
					}
				}
			foreach my $feed_port (@remove_feed_ports){
				my $orig_port=$feed_port;
				$orig_port=~s/^ezfeed_//;
				foreach my $port (@{$instant_port{$instant}}){
					if ($port eq $feed_port){
						$port=$orig_port;
						last;
						}
					}
				}
			}
		$module_string.=$current_module;
		}
	my ($ifc_struct,$inv_ifc_struct);
	($ifc_struct,$inv_ifc_struct)=port_check_ASC($tree_ptr,$level,$struct_name,\%ports,\%size,\%parameter,\%instant_port,\%comment_port); # getting struct ifc
	my @inout_array=split(/\n\n/,$ifc_struct);
	my @wire_array;
	my @in_out_array;
	if ($v1995){
		@in_out_array=split(/\n/,$inout_array[1]);
		@wire_array=split(/\n/,$inout_array[2]);
		}
	else{
		@in_out_array=split(/\n/,$inout_array[0]);
		@wire_array=split(/\n/,$inout_array[1]);
		}
	if ($skipping){
		print "creating $struct_name"."_struct.v struct ...\n";
		open STRUCT , ">$print2dir/$struct_name"."_struct.v" or die "cannot open file $struct_name.v : $!\n";
		print STRUCT "//Auto struct script created by Dror Suliman\n";
#		print STRUCT "//".localtime()."\n\n\n";
		if ($timescale ne ""){
			print STRUCT "`timescale $timescale\n\n";
			}
                if ( exists $import_sv{"$struct_name"}){ 
                    print STRUCT "module $struct_name \n";
                    my @import_arr = split (/,/, $import_sv{"$struct_name"});
                    for my $m (0 .. $#import_arr) {
                        print STRUCT "import $import_arr[$m]::*; \n";
                    }
                    print STRUCT "( \n";
                }
                else{ 
                    print STRUCT "module $struct_name (\n";
                }
                if (defined $stub_out_def){
                    print STRUCT "$ifc_struct\n\n";
                    print STRUCT "`ifndef $stub_out_def\n\n";
                    print STRUCT "$module_string\n\n";
                    print STRUCT "`endif\n\n";
                }else {
		print STRUCT "$ifc_struct\n\n$module_string\n\n";
                }
		if ($if_global_flag and !$level and $vmm){
		   $if_string=~s/,$/);/;
		   print STRUCT "$if_string\n\n";
			}
		print STRUCT "endmodule\n";
		close(STRUCT);
		if ($tb and $level==1){
			my $input="n";
			if (-e "$print2dir/tb_driver_$struct_name.v"){
				if ($owtb==1){$input="y"}
				elsif ($owtb==2){$input="n"}
				else{	print "Do you want to overwrite the tb_driver_$struct_name.v?";
					$input=<STDIN>;
					chomp($input);
					}
#				if ($input eq lc("y")){system("rm -rf $module_library/tb_driver_$struct_name.v");}
				}
			if (($input eq "y") or (!(-e "$print2dir/tb_driver_$struct_name.v"))){
				my $tb_driver_file="";
				if ((-e "$print2dir/tb_driver_$struct_name.txt") or ($tb_driver_txt ne "")){
					if ($tb_driver_txt ne ""){$tb_driver_file=`cat $tb_driver_txt`;}
					else{$tb_driver_file=`cat tb_driver_$struct_name.txt`;}
					}
				else{
					my $number_of_lines;
					if (-e "$print2dir/tb_driver_$struct_name.v" and !$emptytb){
						system("cp $print2dir/tb_driver_$struct_name.v $print2dir/tb_driver_$struct_name.backup");
						$number_of_lines=`cat $print2dir/tb_driver_$struct_name.v | wc -l`;
						chomp($number_of_lines);
						$number_of_lines=~s/\s+//;
						my @first_lines=`grep -n ");" $print2dir/tb_driver_$struct_name.v`;
						if ($first_lines[0]=~/^\s*(\d+)\s*:/){
							if ($1){
								$number_of_lines=$number_of_lines-$1;
								$tb_driver_file=`tail -n $number_of_lines $print2dir/tb_driver_$struct_name.v`;
								}
							}
						$tb_driver_file=~s/\s*endmodule//;
						}
					}
       		print "creating tb_driver_$struct_name.v struct ...\n";
				open TB_DRIVER ,">$print2dir/tb_driver_$struct_name.v" or die "cannot open file : $!\n";
				print TB_DRIVER "//Auto struct script created by Dror Suliman\n";
#				print TB_DRIVER "//".localtime()."\n\n\n";
				if ($tbtimescale ne ""){
					print TB_DRIVER "`timescale $tbtimescale\n\n";
					}
				print TB_DRIVER "module tb_driver_$struct_name (\n$inv_ifc_struct\n";
				print TB_DRIVER "$tb_driver_file\n";
				print TB_DRIVER "endmodule\n";
				close (TB_DRIVER);
            create_ASC_file($struct_name,"tb_driver_$struct_name","$print2dir/tb_driver_$struct_name.v","tb_driver_$struct_name",\%parameters,$find{"tb_driver_$struct_name"},$replace{"tb_driver_$struct_name"},"","","","","",($mem_type eq "hash"),0,"nodef",0);
				}
			}	
		}
#	remove_port_inout_file_by_instance_ASC($module_list_ptr);
#   create_ASC_file($struct_name,"$print2dir/$struct_name"."_struct.v",$struct_name,\%parameters,$find{$struct_name},$replace{$struct_name},"","","","","",($mem_type eq "hash"),0);
	}	
#--------------------------------------------------------------------------------
# This function gets ports and sizes of the struct and returns the interface		
# gets parameters : 																					
#		$inout -- the name of the port		 													
#		$module_library -- the name of the module_library									
#		$tree_ptr -- the pointer to the hash tree													  
# 		$level -- the level in the hash tree 													
#		$current_module -- the struct created													
#		$ports_ptr -- the hash pointer of all the instantiation ports exists in 	
#						  the struct.				 													
#		$size_ptr -- the hash pointer of all the instantiation port sizes exists in
#						  the struct.				 													
# return value: ifc_struct -- the interface of the struct								
#--------------------------------------------------------------------------------
sub port_check_ASC{
	my ($tree_ptr,$level,$current_module,$ports_ptr,$size_ptr,$parameter_ptr,$instant_port_ptr,$comment_port_ptr)=@_;
	my ($inout_string,$inout_order_string,@grep_results,%wire_reg,$in_out,$reg_string,$inv_inout_string);
	my ($struct_ifc,$inv_struct_ifc,$module_list_ptr,$output_counter,$input_counter,$wire_string,$inv_inout_order_string,$comment_string);
	#initial values
	$inout_string="";$inout_order_string="";$wire_string="";$reg_string="";$comment_string="";
	$inv_inout_string="";$inv_inout_order_string="";$inv_struct_ifc="";
	$module_list_ptr=${$tree_ptr}{$level}{$current_module};# the list of instatiation exists in the current struct
	foreach my $instant (sort {$a cmp $b} keys %{$instant_port_ptr}){ # going through the instantiation ports in the struct.
		$inout_string.="// $instant in out ports\n";
		foreach my $key (@{${$instant_port_ptr}{$instant}}) {
#		if ($key=~/^ezfeed/){
#			my $temp_key=$key;
#			$temp_key=~s/^ezfeed_//;
#			${$size_ptr}{$key}=(exists ${$size_ptr}{$temp_key}) ? ${$size_ptr}{$temp_key} : ($feed_through{$temp_key}-1) ? "[".($feed_through{$temp_key}).":0]" : "";
#			${$size_ptr}{$temp_key}=${$size_ptr}{$key};
#			}
		my ($result,$in_out)=port_status_ASC($key,$tree_ptr,$level,$current_module,\%{${$ports_ptr}{$key}}); # internal or external port.
		if (exists $port_size{$current_module}{$key}){${$size_ptr}{$key}=$port_size{$current_module}{$key}};
		$comment_string=(exists ${$comment_port_ptr}{$key}) ? ${$comment_port_ptr}{$key} : "";
		if (($result=~/^\s*1/) and (!(exists $wire_reg{$key}))){ # if the result is external
			# the ifc gets the port type size and name
			if ($B2b and (!$level) and ${$size_ptr}{$key}){ # spread the bus 
				my $loop_num=${$size_ptr}{$key};
				$loop_num=~s/\[(\d+):\d+\]/$1/;
				$wire_string.="wire          ${$size_ptr}{$key}          $key = {";
				for(my $i=$loop_num ; $i>=0 ; $i--){
					if ($v1995){
						$inout_string.="$in_out          $key"."_$i;\n";
						$inout_order_string.="$key"."_$i"."_, ";
						}
					else{
						$inout_string.="$in_out          $key"."_$i,\n";
						}
					$wire_string.="$key"."_$i"."_, ";
					}
				$wire_string=~s/,\s*$//;
				$wire_string.="};\n";
				}
			else{
				if (!defined ${$size_ptr}{$key}){${$size_ptr}{$key}="";}
				if ($v1995){
					$inout_string.="  $in_out  "." " x (6-length($in_out)) ."${$size_ptr}{$key}"." " x (10-length(${$size_ptr}{$key})) ."  $key; "." " x (42-length($key))." $comment_string\n";
					# the order definition in verilog gets the port name also.
					$inout_order_string.="$key, ";
					}
				else{
					$inout_string.="  $in_out  "." " x (6-length($in_out)) ."${$size_ptr}{$key}"." " x (10-length(${$size_ptr}{$key})) ."$key,"." " x (42-length($key))." $comment_string\n";
					}
				}
			$wire_reg{$key}=1;
			if ($tb and ($level==1)){
				my $inv_inout=inv_input($in_out);
				if ($inv_inout eq "output"){$inv_inout.=" $str_reg";}
				elsif ($inv_inout eq "input"){$inv_inout.="    ";}
				if ($v1995){
					$inv_inout_string.="  $inv_inout  "." " x (6-length($in_out)) ."${$size_ptr}{$key}"." " x (10-length(${$size_ptr}{$key})) ."$key;\n";
					$inv_inout_order_string.="$key, ";
					}
				else{
					$inv_inout_string.="  $inv_inout  "." " x (6-length($in_out)) ."${$size_ptr}{$key}"." " x (10-length(${$size_ptr}{$key})) ."$key,\n";
					}
				}				
			}
		if (($result eq "01") and (!(exists $wire_reg{$key}))){ # if it is internal then 
		        ${$size_ptr}{$key} = (defined ${$size_ptr}{$key}) ? ${$size_ptr}{$key} : "";
			$wire_string.="    wire  ${$size_ptr}{$key}"." " x (10-length(${$size_ptr}{$key})) ."$key;\n";  # defines the wire connection between 
																					# ports although we don't have to in verilog. 
			$wire_reg{$key}=1;
			}
		}
	$inout_string=~s/\/\/ $instant in out ports\n$//;
	}
	if ($v1995){
		if (!($inout_order_string=~s/,\s*$/);/)){ # if exists replace the , with );
			$inout_order_string.="  );" # else put ); 
			}
		if ($tb and ($level==1)){
			if (!($inv_inout_order_string=~s/,\s*$/);/)){ # if exists replace the , with );
				$inv_inout_order_string.="  );" # else put ); 
				}
			}
		}
	else{
		my $comment="";
		if ($inout_string=~s/(\/\/\S+\s*)$//){
			$comment=$1;
			}
		if (!($inout_string=~s/,\s*$/$comment );/)){ # if exists replace the , with );
			$inout_string.="  );" # else put ); 
			}
		if ($tb and ($level==1)){
			if (!($inv_inout_string=~s/,\s*$/);/)){ # if exists replace the , with );
				$inv_inout_string.="  );" # else put ); 
				}
			}
		}
	# the interface of the struct.
	if ($v1995){
		$struct_ifc="$inout_order_string\n\n$inout_string\n\n//wire\n$wire_string\n//reg\n$reg_string";
		if ($tb and ($level==1)){
			$inv_struct_ifc="$inv_inout_order_string\n\n$inv_inout_string\n\n";
			}
		}
	else {
		$struct_ifc="$inout_string\n\n//wire\n$wire_string\n//reg\n$reg_string";
		if ($tb and ($level==1)){
			$inv_struct_ifc="$inv_inout_string\n\n";
			}
		}
	return ($struct_ifc,$inv_struct_ifc);	
	}


#--------------------------------------------------------------------------------
# This function gets the input and return value according to							
# output and inputs apear in the design library												
# gets parameters : 																					
#		$inout -- the name of the input port 													
#		$module_library -- the name of the module_library									
#		$tree_ptr -- the pointer to the hash tree													  
# 		$level -- the level in the hash tree 													
#		$current_module -- the struct created													
# return value: 2 bits 'xx' ('1' -- exists , '0' -- not exists)						
#		the left bit regards to outside ports which causes an outside connection	 
# 		the right bit regards to inside connection											
#--------------------------------------------------------------------------------

sub port_status_ASC{
	my ($inout,$tree_ptr,$level,$current_module,$info_ptr)=@_;
	my ($outside_struct,$inside_struct,@grep_results,@info_array,$module_list_ptr,$input_output);
	my ($output_counter_internal,$input_counter_internal,$output_counter,$inout_counter_internal,$input_counter,%top_level_flag);
	#initial values
	$inout=~s/\[.*//;
	$outside_struct=$auto_top;$inside_struct=0;$output_counter=0;$input_counter=0;$inout_counter=0;
	$output_counter_internal=0;$input_counter_internal=0;$inout_counter_internal=0;$input_output="";
	$module_list_ptr=${$tree_ptr}{$level}{$current_module};
	###
	$output_counter_internal=($#{${$info_ptr}{output}}+1); # count the internal outputs
	$input_counter_internal=($#{${$info_ptr}{input}}+1); # counts the internal inputs
	$inout_counter_internal=($#{${$info_ptr}{inout}}+1); # counts the internal inputs
	my $in=($input_counter_internal>0); # checking if there are any outputs for the string below
	my $out=($output_counter_internal>0);# checking if there are any inputs for the string below
	my $inoutport=($inout_counter_internal>0);# checking if there are any inputs for the string below
	$input_output="input" x (($in-$out)*$in) ."output" x $out; # entering the in or out value to the port
	if ($inoutport){$input_output="inout";}
	if ($input_counter_internal and ($output_counter_internal or $inout_counter_internal)){ # if there are inputs and outputs
		$inside_struct=1; # right bit
		$outside_struct=0;# left bit
		}
	if ($mem_type eq "hash"){
	   @grep_results = get_all_arrays($inout_hash_port{$inout});
		 push(@grep_results,grep(/\b$inout\b/,@esig_array)); # looking for the ports in the leaf files 
		}
	else{
		@grep_results=`grep -i "\\b$inout\\b" *.ASC $esig_file`; # looking for the ports in the leaf files 
		}
	my $action=0;
	my $mismatch_flag=0;
	my $port_vec_size=-1;
	my $last_port_vec_size=-1;
	foreach (@grep_results){
		next unless $_!~/^\s*$/;
		if ($_=~/\s*(\w+)\.ASC\s*:\s*(input|output|inout)\s+\[(\d*):\d*\]\s+(\w+)\s+(\S+)\s+\/\/.*/){
			my $instance=$1;  # temp var
			$port_vec_size=($3 ne "") ? $3 : 1;
			my $inout_temp=remove_special_marks($5);
			if ($inout ne $inout_temp){next;}
			if ($last_port_vec_size > 0 and $port_vec_size != $last_port_vec_size and (!exists $port_size{$instance}{$inout})){
				$mismatch_flag=1;
				}
			$last_port_vec_size=$port_vec_size;
			if ((grep(/\b$instance\b/,@{$module_list_ptr}))){next;}  
		  	if ($_=~/\boutput\b/i){
				$output_counter++;$outside_struct=1;
				if ($instance=~/$tree{top_level}/){$top_level_flag{$inout}="output";}}
		  	if ($_=~/\binput\b/i){
				$input_counter++;$outside_struct=1;
				if ($instance=~/$tree{top_level}/){$top_level_flag{$inout}="input";}
			  	}
		  	if ($_=~/\binout\b/i){
				$inout_counter++;$outside_struct=1;
				if ($instance=~/$tree{top_level}/){$top_level_flag{$inout}="inout";}
			  	}
			}
		elsif (($_=~/$esig_file\s*:\s*(input|output|inout)\s+\[\d*:\d*\]\s+(\w+)/) or ($_=~/$esig_file\s*:\s*(input|output|inout)\s+(\w+)/)){
		  	if ($1 eq "input"){
				$outside_struct=1;
				}
		  	if ($1 eq "output"){
				$outside_struct=1;
			  	}
		  	if ($1 eq "inout"){
				$outside_struct=1;
			  	}
			}
		}
		### top level interface check ###
		#------------------------- debug prints --------------------------------------
		#  print "$inout $current_module\nresults @grep_results\n";
		#  print "output count: $output_counter int output:$output_counter_internal\n"; 
		#  print "input count: $input_counter int input:$input_counter_internal\n"; 
		#  print "print to outside : $outside_struct inside : $inside_struct\n";
		#------------------------- debug prints --------------------------------------
	  	if (($output_counter+$output_counter_internal)>(1 + (exists $top_level_flag{$inout}))){
			if (!(exists $split{$inout})){print "** Error -- There are too many outputs with the same name : $inout\n";	
				print LOG "Check instances:\n";
				print_port_output_results($inout);
				exit(1);}
			}
	  	if ((($input_counter+$input_counter_internal)>0) and (($output_counter+$output_counter_internal)==0)){
			if (!$top_level_flag{$inout} and (!$auto_top)){print2log("The port $inout is driven by no module in module : $current_module","error");}
		 	}
	  	if ((($input_counter+$input_counter_internal)==0) and (($output_counter+$output_counter_internal)>0)){
			if (!$top_level_flag{$inout} and !$auto_top){print2log("The out port $inout is not connected in module : $current_module","warning");}
			}
		if ($mismatch_flag and (!exists $mismatch{$inout})){
			$mismatch{$inout}=1;
#			print2log("There are mismatches in port $inout","warning");
			print_port_mismatch_size($inout);
			}
	return ("$outside_struct"."$inside_struct",$input_output);
	}


#-------------------------------------------------------------------------------
# This function process the tree information 					 							
# gets parameters : 																					
#		$instantiation - instantiation information from the tree 						
# returns:																													
# 		$number -- the instatitaion number if it is duplicated							
# 		$txt_addition -- if there is an additional txt to the port  					
# 		$instatiation -- the instatitiaion name 							  					
#-------------------------------------------------------------------------------

	
sub tree_info_processor_ASC{
	my ($instantiation)=@_;
	my ($module,$instatiation,$number,$txt_addition,$special_addition,@special_additions,@special_instatnt,$num_addition,$num_additioni,$file_name,$file_name_original,$gen);
	my $string;
	my $if_flag;
	$txt_addition="";$num_addition="";$num_additioni="";
	if($mem_type eq "hash"){
		$string=${$inout_hash{$instantiation}}[0];
		}
	else{
		$string=`head -n 1 $instantiation.ASC`
		}
	my @txt_num=split(/:/,$string);
	if (defined $txt_num[2] and $txt_num[2] ne ""){
		$txt_addition="$txt_num[2]"."_";
		}
	if (defined $txt_num[4] and $txt_num[4] ne ""){
		$num_addition="_$txt_num[4]";
		}
	if (defined $txt_num[5]){
		$num_additioni="_$txt_num[5]";
		}
	($module,$if_flag)=($txt_num[0]=~/-/) ? split(/-/,$txt_num[0]) : ($txt_num[0],"");
	$file_name="$instantiation.ASC";
	$file_name_original=$txt_num[1];
	my $gen_flag= (defined $txt_num[3] and $txt_num[3]=~s/gen//) ?  1 : 0 ; 
	return ($module,$instantiation,$txt_addition,$txt_num[3],$num_addition,$num_additioni,$file_name,$file_name_original,$gen_flag,$if_flag);
	}
#-------------------------------------------------------------------------------
# This function look for the correct file_name					 								
# gets parameters : 																						
#		$module - module instantiation we are looking for 										
# 		$module_library -- design lib																	   	 
# returns:																									   			 
# 		$file_name -- the file_name 																	
#-------------------------------------------------------------------------------

sub file_name_processor_ASC{
	my ($module,$file_array_ptr,$hash)=@_;
	my ($file_name,$number,@results,@file_name,$txt_addition,$num_addition,$num_additioni);
	foreach my $file (@{$file_array_ptr}){
		foreach my $suffix (@suffix_array){
   		foreach my $ext ("" , @extension_array){
			   if ($file=~/\b$module$ext$suffix$/){
          		push(@file_name,$file);
					}
				}
			}
		}
	for(my $i=0; $i<$#file_name+1; $i++){
		if ($file_name[$i]=~/~\s*$/ or $file_name[$i]=~/\.vh\s*$/){
			splice_array($i--,\@file_name);
			}
		}
	if ($#file_name > 0){
		if ($rmd){}
		else{
			print2log("$file_name[0] appears more then once\n\t\tThe files : @file_name\n","error");
			}
		}
	if (!(defined $file_name[0])){
	   if ($hash) {
		  my $file_name = ${$inout_hash{$module}}[0];
		  if (!(defined $file_name)){
      		return $module;
  		  	}
		  $file_name=~s/^\w+:(\S+?):.*/$1/;
		  return $file_name;
		  }
		elsif (-e "$module.ASC"){
			my $file_name=`head -n 1 $module.ASC`;
			chomp($file_name);
			$file_name=~s/^\w+:(\S+?):.*/$1/;
			return $file_name;
			}
		return $module;
#		print "*Error -- there is no such file $module(_struct.v|_behavioral.v|.v)\n";
#		exit(1);
		}
	chomp($file_name[0]);
	return $file_name[0];
	}

#-------------------------------------------------------------------------------
# This function translating vhdl interface to verilog			 							
# gets parameters : 																					
#		$vhdl_line -- the line from vhdl 														
# returns:																								   				 
# 		$verilog_line -- verilog intrface line													
#-------------------------------------------------------------------------------

sub interface_vhdl2verilog_ASC_file{	
	my ($vhdl_line,$vhdl_generic_flag)=@_;
	my ($verilog_line,$port,$inout,$size,$comments);
	$verilog_line="";
	$comments=$vhdl_line;
	$vhdl_line=~s/--.*//;
	if ($vhdl_line=~/entity\s+(\w+)/i){
		$verilog_line="module $1\n";
		}
   elsif (($vhdl_line=~/\bgeneric\s*\(/i) or $vhdl_generic_flag){
	 	$vhdl_generic_flag=1;
		if ($vhdl_line=~/\);/){$vhdl_generic_flag=0;}
		if ($vhdl_line=~/\s*(\w+)\s*:\s*\S+\s*:=\s*(\S+)/){
			my $val=$2;
			my $param=$1;
			$param=fix_var($param);
			$param=~s/\s+//g;
			$val=~s/;\s*$//;
			$verilog_line="parameter $param=$val\n";
			}
		}
	if ($vhdl_line=~/(\w+)\s*:\s*(\bin\b|\bout\b|\binout\b)\s+(.*)/i){
		$port=lc($1);$inout=lc($2);$size=lc($3);
		if ($inout eq "inout"){$verilog_line=$inout;}
		else{$verilog_line=$inout."put";}
		if ($size=~/_vector/i){
			$size=~/\(\s*(.*)\s+downto\s+(.*)\s*\)/i;
			my $msb=$1;
			my $lsb=$2;
			$msb=~s/\s+//g;
			$lsb=~s/\s+//g;
			$verilog_line.=" [$msb:$lsb]";
			}
		$verilog_line.="          $port";
		if ($comments=~/--(.*)/i){
			my $comment=$1;
			$comment=~s/asc/ASC/g;
			$verilog_line.=" // $comment";
			}
		}
	elsif ($vhdl_line=~/architecture/i){$verilog_line="architecture";}
	return ($verilog_line,$vhdl_generic_flag);
	}
#-------------------------------------------------------------------------------
# This function return the grep index of an element in an array						
# gets parameters :																					
#		$element		 																					
#		$array_ptr -- array pointer																
# returns:																								   				 
# 		$index -- the position of the element in the array 								
#-------------------------------------------------------------------------------

sub my_grep2{
	my ($element1,$array_pointer,$array_flag)=@_;
	my (@array);
	for(my $i=0;$i<=$#{$array_pointer};$i++){
		chomp(${$array_pointer}[$i]);
		if (${$array_pointer}[$i] eq $element1){
			if ($array_flag){
				push(@array,$i);
				}
			else{
				return $i;
				}
			}
		}
	if ($array_flag and @array){
		return \@array;
		}
	return -1;
	}
#-------------------------------------------------------------------------------
# This function checks the existance of a file 						 							
# gets parameters :																						
#		$element		 																						
#		$array_ptr -- array pointer																	
# returns:																													  
# 		$index -- the position of the element in the array 									
#-------------------------------------------------------------------------------

sub check_file{
	my ($file_name,$library,$file_overwrite_pointer)=@_;
	my ($input);
	if (-e "$library/$file_name"){
		print "**Warning the file $file_name already exists\n";
		while(1){
			print "Do you want to overwrite?(y=yes,yta=yes to all,nta=no to all,n=no,q=quit)";
			$input=<STDIN>;
			chomp($input);
			if ($input){last; next;}
			}
		if ($input eq "y"){return 0;}
		elsif ($input eq "yta"){ ${$file_overwrite_pointer}=3 ;return 0;}
		elsif ($input eq "nta"){ ${$file_overwrite_pointer}=2 ;return 1;}
		elsif ($input eq "q"){print "exit ...\n"; exit;}
		else {return 1;} 
		}
	return 0;
	}

#-------------------------------------------------------------------------------
# This function fix variables	chomp the var and delete all spaces							
#-------------------------------------------------------------------------------

sub fix_var{
	my ($var)=@_;
	chomp($var);
	my $CLOG2 = ($var=~s/(\$clog2\(.*\))/TEMPORARY_CLOG/) ? $1 : "";
	$var=~s/\s*;\s*$//;
	$var=~s/\s*,\s*$//;
	$var=~s/\s*\)\s*\(?\s*$//;
	$var=~s/TEMPORARY_CLOG/$CLOG2/;
	return $var;
	}

#-------------------------------------------------------------------------------
# This function inverse all ports																	
# if the function gets input it returns output and the other way around					
#-------------------------------------------------------------------------------

sub inv_input{
	my ($in_out)=@_;
	if (($in_out eq "input") or (lc($in_out) eq "in")){
		return "output";
		}
	elsif (($in_out eq "output") or (lc($in_out) eq "out")){
		return "input";
		}
	elsif (lc($in_out) eq "inout"){
		return "inout";
		}
	}

#-------------------------------------------------------------------------------
# This function prints the ASC Usage																
#-------------------------------------------------------------------------------

sub Usage{
	print "//////////////////////////////////////////////////////////////////////////////\n";
	print "Automatic signal connector is a script design to create structs automatically.\n";
	print "Usage : $0 <module_directory> [OPTION]...\n";
	print "//////////////////////////////////////////////////////////////////////////////\n";
	print "For more Help print $0 --help\n";
	exit(1);
	}

#-------------------------------------------------------------------------------
# This function erase comments in a line 															
#-------------------------------------------------------------------------------

sub erase_comments{
	my ($line)=@_;
	$line=~s/\/\/.*//g;
	$line=~s/--.*//g;
	return $line;
	}
	

#-------------------------------------------------------------------------------
# This function erase ports from the input_output file according to  instance name	
#
sub remove_port_inout_file_by_instance_ASC{
	my ($top,$array_ptr)=@_;
	if ($mem_type eq "hash"){
		foreach (@{$array_ptr}){
			delete $inout_hash{$_};
		    foreach my $port (keys %inout_hash_port){
			 	if (exists ($inout_hash_port{$port}{$_})){
					delete $inout_hash_port{$port}{$_};
					}
			 	}
			}
		}
	else{
		foreach (@{$array_ptr}){
			system("rm -f $_.ASC");
			}
		}
}

#-------------------------------------------------------------------------------
# This function gets the constant information from the package file 						
#-------------------------------------------------------------------------------

sub constant_info{
	my ($package)=@_;
#	print "Gathering package info from file $package ...\n";
	open FILE , $package or die "cannot open file $package : $!\n";
	while (<FILE>){
		$_=erase_comments($_);
		if ($_=~/^\s*constant\s+(\w+)\s*:\s*integer\s*:=\s*(.*)\s*;\s*/i){
			my $result=calc_param($2,\%constant,$package);
			$constant{$1}=$result;
			}
		elsif ($_=~/define\s+(\w+)\s+(\S+)/i){
			my $result=calc_param($2,\%constant,$package);
			my $key="$1";
			$constant{$key}=$result;
			}
		elsif ($_=~/(parameter|localparam)\s+(\w+)\s*=\s*(\S+)\s*(;|,)/){
			my $result=calc_param($3,\%constant,$package);
			my $key="$2";
			$constant{$key}=$result;
			}
		}
	close(FILE);
	}

#-------------------------------------------------------------------------------
# This function calculates the size of vectors according to parameters and constants
#-------------------------------------------------------------------------------

sub calc_param{
	my ($input,$ptr,$package)=@_;
	my ($res);
	my $orig_input = $input;
	$input=~s/\s+//g;
	$input=~s/\`//g;
	if ($input=~/^\d*'(b|h|d)[0-9A-Fa-f_]+$/){return $input;}
	elsif ($input=~/\D+/){
		foreach my $key (keys %{$ptr}){
			my $temp=${$ptr}{$key};
			$input=~s/\b$key\b/$temp/g;
			}
		if ($input=~/\$clog2\(([\d+-\/]*)\)/){
		   my $logres = (ceil(log(eval($1))/log(2)));
			$input =~ s/\$clog2\(([\d+-\/]*)\)/$logres/;
			}
		if ($input=~/[A-Z|a-z]/){ print2log("Cannot evaluate $input in package/instant $package","warning")}
		else{$res=eval($input);}
		if ($input=~/\d+\{\d*'(b|h|d)[0-9A-Fa-f_x]\}/){
		   $res=$input;
			}
		elsif (!defined $res){
			$res=$orig_input;
			}
		}
	else{
		$res=$orig_input;
		}
	return $res;
	}

#-------------------------------------------------------------------------------
# This function avaluate the biggest vector size
#-------------------------------------------------------------------------------

sub check_size{
	my ($size,$last_size,$constant_ptr)=@_;
	my ($msb1,$msb2);
	if ($size=~/\[(\w+):(\w+)\]/){
		$msb1=$1;
		}
	else { $msb1 = 0} 
	if ($last_size=~/\[(\w+):(\w+)\]/){
		$msb2=$1;
		}
	else { $msb2 = 0} 
	if ($msb1 > $msb2){
		return $size;
		}
	return $last_size;
	}


#-------------------------------------------------------------------------------
# This function print the exceptions file usage
#-------------------------------------------------------------------------------

sub connectivity_usage{
	print "#!/usr/bin/perl -w\n";
	print "#File_name : PCS_info.pl\n";
	print "#Prameters - Connectivity - Split - Drive\n";
	print "#####################################################################################################################\n";
	print "# To connect port to different wire then it is soppuse to be: \$connect2{<instance name>}{<instance port>}=<wire name>\n";
	print "###########################Add your connections here################################################################\n";
	print "\n";
	print "\n";
	print "###############################end of connections###################################################################\n";
	print "# To define your own port size : \$port_size{<instance name>}{<instance port>}=\"[<num>:0]\"\n";
	print "###########################Add your port size here #################################################################\n";
	print "\n";
	print "\n";
	print "###############################end of port size ####################################################################\n";
	print "# For splitted port The Hash \$split{<instance name>}{<instance port>}=\"[4:0]\";\n";
	print "# For output name identical in both instances add \$split{<output port name>}=1;\n";
	print "############################ Add your splits here ##################################################################\n";
	print "\n";
	print "\n";
	print "############################### end of splits	#####################################################################\n";
	print "# For instance parameters \$parameters{<instance name>}{<parameter>}=\"<parameter value>\";\n";
	print "############################ Add your parameters here ##############################################################\n";
	print "\n";
	print "\n";
	print "############################### end of parameters###################################################################\n";
	print "# To drive ports \$drive{<instance name>}{<port name>}=\"[1|0|]\";\n";
	print "############################ Add your drivers here #################################################################\n";
	print "\n";
	print "\n";
	print "############################### end of drivers #####################################################################\n";
	print "# To change port connection name \$connect2{<instance name>}{<port name>}=\"<wire name>\";\n";
	print "############################ Add your drivers here #################################################################\n";
	print "\n";
	print "\n";
	print "############################### end of drivers #####################################################################\n";
	print "1; \n";
	print "\n";
	print "\n";
	exit(1);
	}
#-------------------------------------------------------------------------------
# This function print the project tree file usage
#-------------------------------------------------------------------------------

sub tree_usage{
	print "\n";
	print "\n";
	print "tamplate for the tree file: (the file must include the red color word,yelow color parameter are optional)\n";
	print color("red"),"top_level: ",color("reset");
	print "<top level module name>\n";
	print color("red"),"\t1)",color("reset")," <leaf module name>",color("yellow")," [(prefix)(num of duplication)|(num of duplication)] [options..]\n",color("reset");
	print color("red"),"\t1)",color("reset")," <struct module name>\n";
	print color("red"),"\t\t2)",color("reset")," <leaf module name>",color("yellow")," [(prefix)(num of duplication)|(num of duplication)] [options..]\n",color("reset");
	print color("red"),"\t\t2)",color("reset")," <leaf module name>",color("yellow")," [(prefix)(num of duplication)|(num of duplication)] [options..]\n",color("reset");
	print color("red"),"\t1)",color("reset")," <struct module name>\n";
	print color("red"),"\t\t2)",color("reset")," <leaf module name>",color("yellow")," [(prefix)(num of duplication)|(num of duplication)] [options..]\n",color("reset");
	print color("red"),"\t\t2)",color("reset")," <leaf module name>",color("yellow")," [(prefix)(num of duplication)|(num of duplication)] [options..]\n",color("reset");
	print color("red"),"\t\t2)",color("reset")," <struct module name>\n";
	print color("red"),"\t\t\t3)",color("reset")," <leaf module name>",color("yellow")," [(prefix)(num of duplication)|(num of duplication)] [options..]\n",color("reset");
	print color("red"),"\t\t\t3)",color("reset")," <leaf module name>",color("yellow")," [(prefix)(num of duplication)|(num of duplication)] [options..]\n",color("reset");
	print "\n";
	print "The options above includes:\n";
	print "\t-pre <prefix output module name>\t:check the prefix of your outputs from the module (according to methodology)\n";
	print "\t-gen\t\t\t\t\t:generate instead of duplicate\n";
	print "\t-offset <number> \t\t\t:start the duplication from <number> other number then zero\n";
	print "\n";
	print "example:\n";
	print "top_level: top\n";
	print "\t1) leaf1 (40) -pre leaf1\n";
	print "\t1) struct1\n";
	print "\t\t2) leaf2 (2)(bool) -pre leaf2\n";
	print "\t\t2) leaf3 (2)(flow) -offset 4 -pre leaf3\n";
	print "\t1)struct2\n";
	print "\t\t2) leaf4 (3) -gen  -pre leaf4\n";
	
	exit(1);
	}

#-------------------------------------------------------------------------------
# This function prints to the log file run_ASC.log
#-------------------------------------------------------------------------------

sub print2log{
	my ($string,$status)=@_;
		if (lc($status) eq "error"){
			print LOG "**Error - $string\n";
			print "**Error --> check out run_ASC.log\n";
			exit(1);
			}
		elsif (lc($status) eq "warning"){
			print LOG "**Warning - $string\n";
			$warning=1;
			}
		else{
			print LOG "$string\n";
			}
	}

#-------------------------------------------------------------------------------
# This function remove element from array
#-------------------------------------------------------------------------------

sub splice_array{
	my ($result,$array_ptr)=@_;
	if ($result>=0){
		splice(@{$array_ptr},$result,1);
		}
	}


#-------------------------------------------------------------------------------
# This function prints color message 
#-------------------------------------------------------------------------------
sub color {
    my @codes = map { split } @_;
    my $attribute = '';
	 my %attributes = ('clear'      => 0,
               'reset'      => 0,
               'bold'       => 1,
               'underline'  => 4,
               'underscore' => 4,
               'blink'      => 5,
               'reverse'    => 7,
               'concealed'  => 8,

               'black'      => 30,   'on_black'   => 40, 
               'red'        => 31,   'on_red'     => 41, 
               'green'      => 32,   'on_green'   => 42, 
               'yellow'     => 33,   'on_yellow'  => 43, 
               'blue'       => 34,   'on_blue'    => 44, 
               'magenta'    => 35,   'on_magenta' => 45, 
               'cyan'       => 36,   'on_cyan'    => 46, 
               'white'      => 37,   'on_white'   => 47
	       );

    foreach (@codes) {
        $_ = lc $_;
        unless (defined $attributes{$_}) {
            require Carp;
            Carp::croak ("Invalid attribute name $_");
        }
        $attribute .= $attributes{$_} . ';';
    }
    chop $attribute;
    ($attribute ne '') ? "\e[${attribute}m" : undef;
}


sub block_check_ASC{
	my ($port,$txt_addition)=@_;
	my $block_check=0;
	if ($port=~/xxxxx/i){
		if ((defined $txt_addition) and ($txt_addition ne "") and ($txt_addition ne "_")){
			$txt_addition=~s/_$//;
			$port=~s/xxxxx/$txt_addition/;
			$block_check=1;
			}
		}
	return ($port,$block_check);
	}

sub regex_ASC{
	my ($port,$find,$replace,$number)=@_;
	my ($flag);
	$flag=0;
	my $offset=0;
	if ($find=~s/\?(\d+)//){
#        print "DBG: Input to sub:\n$port, $find, $replace, $number\n";
		if ($number != $1){return $port;}
		}
	if ($replace=~s/\{(\d+)\}//){
		$number+=$1;
		}
	if ($port=~/$find/){
		if ($replace=~s/-$//){$flag=1;}
		if (($replace=~/(\w*)variable(\w*)/i) and (defined $number)){
			$number=~s/^\s*_//;
			$replace=~s/variable/$number/g;
			$port=~s/$find/$replace/;
			if ($flag){
				$port=~s/_(x|i)$//;
				}
			}
		elsif ($port=~/$find/i){
			my $flag=0;
			my @regex_mem;
			my $tmp_replace=$replace;
			while ($tmp_replace=~s/\$(\d+)//){
			   $flag=($flag > $1) ? $flag : $1;
			   }
			$port=~s/$find/$replace/;
			for(my $i=1;$i<=$flag;$i++){
				push(@regex_mem,${"$i"});				
				}
			for(my $i=1;$i<=$flag;$i++){
				my $str="\\\$".$i;
				my $strreplace=$regex_mem[$i-1];
				$port=~s/$str/$strreplace/;
				}
			}
		}
	return $port;
	}

sub find_replace_ASC{
	my ($port,$find_ptr,$replace_ptr,$number)=@_;
	for(my $i=0;$i<=$#{$find_ptr};$i++){
		$port=regex_ASC($port,${$find_ptr}[$i],${$replace_ptr}[$i],$number);
		}
	return $port;
	}

sub create_ASC_file{
	my ($module_top,$module,$file,$instance,$parameter_ptr,$find_ptr,$replace_ptr,$txt_addition,$iterations,$num_add,$inum_add,$prefix,$hash,$gen_flag,$def,$noparam)=@_;
	if (!($file)){return;};
	if (!(-e $file)){return;};
	my ($comments,$vhd,$in_out_ptr,$size_ptr,$ports_ptr);
	my $parameter_flag=0;
	my $if_flag=0;
	my $if_flag2=0;
	my $string="";
	my @file_array;
	my $def_flag=1;
	my $module_flag=1;
	$vhd= ($file=~/\.vhd\s*/) ? 1 :0 ; # check if the file is a vhdl file 
	my $temp_str = "nomodule:$file:$txt_addition:"."gen" x $gen_flag ."$iterations:$num_add:$inum_add";
	$string.="$temp_str\n"; 
	push (@{$inout_hash{$instance}},"$temp_str");
	$string.="$prefix\n"; 
	push (@{$inout_hash{$instance}},"$prefix");
	if (defined $find_ptr){
	   $temp_str = "f: @{$find_ptr}";
		$string.= "$temp_str\n"; 
		push (@{$inout_hash{$instance}},"$temp_str");
	   $temp_str = "r: @{$replace_ptr}";
		$string.= "$temp_str\n"; 
		push (@{$inout_hash{$instance}},"$temp_str");
		}
	else{
		$string.= "f: \n"; 
		$string.= "r: \n"; 
		push (@{$inout_hash{$instance}},("f: ","r: "));
		}
	my $define_counter=0; 
	my $module_name="nomodule";
	my @function_to_activate;
	############################################################
	# checking if there are functions for this module/instance #
	############################################################
	foreach my $function_name (keys %ASCfunc){
   	if (eval "defined(&$function_name)"){
		  my $flag = $function_name ->($module,$instance,$prefix);
		  $tmp_function_to_activate = $ASCfunc{$function_name};
		  if ($flag and eval "defined(&$tmp_function_to_activate)"){
		      print2log("$tmp_function_to_activate activated on module $module","print");
		   	push(@function_to_activate,$tmp_function_to_activate);
		   	}
		 }
		else{
		   print2log("No such ASCfunc function $function_name","warning");
			}
		}
	open FILE ,"$file" or die "cannot open file $file : $!\n";
	while (<FILE>){
		chomp($_);
    	if (check_line_ASC($_)){next;}
    	if (check_endmodule_ASC($_)){last;}
		$def_flag=check_def_line($_,$def,$def_flag,\$define_counter);
		if (!$def_flag){next;}
		if ($vhd){
			($_,$parameter_flag)=interface_vhdl2verilog_ASC_file($_,$parameter_flag);
			if ($_ eq "architecture") {last;}
			}
		my $wait;
		($wait,$comments,$_)=comments_analyzer_ASC($_,$vhd);
		$_=erase_comments($_);
		$_=remove_functions($_);
		$_=remove_tasks($_);
		$_=remove_sv_clocking($_);
		my $string_ptr;
		my $interface_str;
		($string_ptr,$parameter_flag,$if_flag)=line_analyzer_ASC_file($module_top,$_,$parameter_ptr,$instance,$parameter_flag,$if_flag,$instance,$noparam);
		($module_name,$interface_str)=get_module_name($_);
		if ($module_name ne "nomodule" and $module_flag){
		   if (!($hash)){
   			$string=~s/^nomodule:/$module_name$interface_str:/;
				}
			else{
			   ${$inout_hash{$instance}}[0] =~s/^nomodule:/$module_name:/;
				}
			$module_flag=0;
			}
		foreach my $str (@{$string_ptr}){
			if (($if_flag2==1 or $if_flag==1 or ($if_flag==2 and $if_flag2==0)) and $str!~/^\s*parameter/){
				my ($inout_type,$inout_size,$port_name,$wire_name,$str_comment)=get_connected_port_ASC($module_top,$str,$comments,$wait,$prefix,$txt_addition,$iterations,$num_add,$inum_add,$find_ptr,$replace_ptr,$gen_flag,$instance,\@function_to_activate);
	         $str = "$inout_type $inout_size $port_name $wire_name $str_comment";
#				$inout_hash_port{$wire_name}{$instance}{$module_top} = "$str";
            $wire_name=clean_wire_name($wire_name);
				$inout_hash_port{$wire_name}{$instance} = "$str";
				}
			if (!($hash)){
				$string.="$str\n";
				}
			else{
      		push (@{$inout_hash{$instance}},"$str");
				}
			}
		$if_flag2=$if_flag;
		}
	close(FILE);
	if (!($hash)){
		open OUTFILE ,">$instance.ASC" or die "cannot open file $instance.ASC : $!\n";
		print OUTFILE $string; 
		close(OUTFILE);
		}
	if ($module_name eq "nomodule" and $module_flag){
		print LOG "**Error -- no module name in instance $instance define $def\n";
		print "**Error -- no module name in instance $instance define $def\n";
		exit(1); 
		}
	}


sub get_connected_port_ASC{
	my ($module_top,$line,$comment,$next_level,$prefix,$txt_addition,$iterations,$num_add,$inum_add,$find_ptr,$replace_ptr,$gen_flag,$instance,$func_array_ptr)=@_;
	if (check_line_ASC($line)){next;}
	my @prefixs;
	if ($prefix ne ""){
		$prefix=~s/^\(//;
		$prefix=~s/\)$//;
		@prefixs=split(/\)\(/,$prefix);
		}
	my @objects=split (/\s+/,$line);
	my $orig_port = $objects[2];
	my $inout_type = $objects[0];
   my $port_size = $objects[1];
	my $txt = $txt_addition;
	### ability to use functions of specific instances\modules
	if ($txt_addition ne ""){
	   if ($comment=~/-ASC(x|s|i)(\d*)/){
		   my $ascprefix = (defined $2) ? "-ASCpre$2" : "";
			$ascprefix=" ASCp: ${orig_port}_$1 $ascprefix";
			$comment=~s/-ASC(\w)(\d*)/$ascprefix/;
			}
# 		if (exists $ASCpre{$instance}{$orig_port}){
# 		   print "@prefixs\n";
# #		   if (!defined $prefixs[$ASCpre{$instance}{$orig_port}]){print2log("No such prefix index $ASCpre{$instance}{$orig_port} in instance $instance","error")};
# 		   $txt = $prefixs[$ASCpre{$instance}{$orig_port}];
# 			}
		if ($comment=~s/-ASCpre(\d+)//){
		   if (!defined $prefixs[$1-1]){print2log("No such prefix index ".($1-1)." in instance $instance","error")};
			$txt=$prefixs[$1-1]
			}
		elsif ($comment=~s/-ASCprevar//){
			if ($num_add!~/\d+/){print2log("The -ASCprevar is no placed correctly in instance $instance ","error");}
			$txt=$prefixs[$num_add-1]
			}
		}
	my $port = ($comment=~s/ASCp:\s*(\w+)//) ? $1 : $orig_port;
	foreach my $function_name (@{$func_array_ptr}){
	  if (eval "defined(&$function_name)"){
	      $port=$function_name->($port,$inout_type,$port_size,$instance);
			}
	  else{
	  	print "Warning -- No such function $function_name for module $module instance $instance\n";
		print2log("No such function $function_name for module $module instance $instance","warning");
	  	}  
	  }
	my $check_xxxx=0;
	($port,$check_xxxx)=block_check_ASC($port,$txt);
	$port=find_replace_ASC($port,$find_ptr,$replace_ptr,$num_add);
	if ($next_level==0){
		if ($port=~/_x$/){
			if ($gen_flag){
				$port=~s/_x$/=/; # = mark if the port needs generate
				}
			else{
				if ($num_add ne ""){$port=~s/_x$//;$port=$port."_$num_add";}
				}
  		 	if ($txt ne "" and (!$check_xxxx)){$port=~s/_x$//;$port=$txt."_".$port;}
  	 		elsif ($txt ne "" and ($check_xxxx)){$port=~s/_x$//;}
			}
		elsif ($port=~/_s$/){
			if ($txt ne "" and !$check_xxxx){$port=~s/_s$//;$port=$txt."_".$port;}
			elsif ($check_xxxx){$port=~s/_s$//;}
			}
		elsif ($port=~/_i$/){
			if ($gen_flag){
				$port=~s/_i$/=/;
				}
			elsif ($inum_add ne ""){
				$port=~s/_i$//;$port=$port."_$inum_add";
				}
			}
		}
	if ($objects[0] eq 'output'){
		my $temp_port=remove_special_marks($port);
		$hash_port{$temp_port}=(exists $hash_port{$temp_port}) ? $hash_port{$temp_port}+1 : 1;
		}
	if (exists $connect2{"$module_top.$instance"}{$orig_port}){
		$port=remove_spaces($connect2{"$module_top.$instance"}{$orig_port});
		if ($gen_flag){$port=~s/_(x|i)$/=/;}
		}
	elsif (exists $connect2{$instance}{$orig_port}){
		$port=remove_spaces($connect2{$instance}{$orig_port});
		if ($gen_flag){$port=~s/_(x|i)$/=/;}
		}
	if (exists $drive{"$module_top.$instance"}{$orig_port}){
		$port="EMPTY";
		}
	elsif (exists $drive{$instance}{$orig_port}){
		$port="EMPTY";
		}
	my $msb= ($line=~/\[(\d+):\d+\]/) ? $1 : 1;
	return ($objects[0],$objects[1],$objects[2],$port,$comment);
	}

sub comments_analyzer_ASC{
	my ($line,$vhd)=@_;
	my $comment_line="//";
	my $wait=0;
	# No vhd
#	my $str=($vhd) ? "\-\-" : "\/\/";
	my $str="\/\/";
	if ($line=~/(^|\w+)\s*\/\*/){
		$line=~s/\/\*/\/\//;
		while (<FILE>){
			chomp($_);
			$line.=$_;
			if ($line=~/\*\//){last;}
			}
		}
	if ($line=~/$str.*ASCp\s*:\s*(\w+)/){
		$comment_line.="ASCp:$1";
		}
	if ($line=~/$str.*ASCl(\d+)/){
		$wait=$1;
		if ($wait>1){
			$comment_line.="-ASCl".($wait-1);
			}
		}
	if ($line=~/$str.*(-ASCpre\d+)/){
		$comment_line.="$1";
		}
	elsif ($line=~/$str.*(-ASCprevar)/){
		$comment_line.="$1";
		}
	elsif ($line=~/$str.*(-ASC(s|x|i)\d*)/){
		$comment_line.="$1";
		}
	return ($wait,$comment_line,$line);
	}

sub line_analyzer_ASC_file{
	my ($module_top,$line,$parameter_ptr,$instant,$parameter_flag,$if_flag,$instance,$no_parameter)=@_;
	my (@string,$port_str,@port,$inout,$in_out_string,$size,$msb,$lsb,$ok,@lines);
	chomp($line);
	$ok=0;
	if ((($line=~s/\bparameter\b//gi) or ($parameter_flag==1)) and !$no_parameter){
		$parameter_flag=1;
		my @parameter=split(/,/,$line);
		if ($line=~/(\)|;)/ and $line!~/\)\s*,/ and $line!~/\)\s*\?/ and $line!~/\)\s*\&/  and $line!~/\)\s*\|/){$parameter_flag=0;}
		foreach my $parameter ( @parameter){
			$parameter=~s/\s+//g;
            #print "\nDBG Yossef 0 : $parameter\n"; 
			if ($parameter=~/(\w+)\s*=\s*(\S+)/i){
                #print "\nDBG Yossef 1 : $parameter\n"; 
				my $number=$2;
				my $param=$1;
				$number=(exists ${$parameter_ptr}{"$module_top.$instance"}{$param}) ? ${$parameter_ptr}{"$module_top.$instance"}{$param} : (exists ${$parameter_ptr}{$instance}{$param}) ? ${$parameter_ptr}{$instance}{$param} : calc_param(fix_var($number),$parameter_ptr,$instant);
				if (exists ${$parameter_ptr}{"$instance.$module_top"}{$param}){
					print "param $param $instance $module_top\n";
					}
				push(@string,"parameter $param=$number");
				${$parameter_ptr}{$param}=$number;
				}
			}
		}
	elsif ($if_flag!=2){
		if ($line=~/,\s*(\binput\b|\boutput\b|\binout\b)/){@lines=split(/,/,$line);}
		else{push(@lines,$line);}
		foreach $line (@lines){
			$line=~s/^\s*\(//;
			if ($line=~/^\s*(\binput\b|\boutput\b|\binout\b)\s*(\breg\b|\bwire\b|\bbit\b|)\s*\[\s*(.*)\s*:\s*(\S+)\s*\]\s*(\w+.*)/){
				$parameter_flag=0;
				$if_flag=1;
				$inout=$1;
				$in_out_string=$5;
				$in_out_string=fix_var($in_out_string);
				$msb=$3;
				$lsb=$4;
				my %total_param_hash = (%constant , %{$parameter_ptr});
#				$msb=calc_param($msb,$parameter_ptr);
				$msb=calc_param($msb,\%total_param_hash,$instant);
				$size="[$msb:$lsb]";
				$msb=~s/(\[|\]|:)//g;
				if ($msb=~/\D+/ && (!keys %import_sv) ){print "There is no $msb parameter in $instant\n";}
					if ($in_out_string=~/,/){
						$in_out_string=~s/,\s*$//;
						@port=split(',',$in_out_string);
						for (my $i=0;$i<=$#port;$i++){
         				push(@string,"$inout $size $port[$i]");
							}
						}
					else{
        				push(@string,"$inout $size $in_out_string");
						}
					}
			elsif($line=~/^\s*(\binput\b|\boutput\b|\binout\b)\s*(\breg\b|\bwire\b|\bbit\b|)\s*(.*)/){
				$parameter_flag=0;
				$if_flag=1;
				$inout=$1;
				$in_out_string=$3;
				$in_out_string=fix_var($in_out_string);
				if ($in_out_string=~/,/){
						@port=split(',',$in_out_string);
						for (my $i=0;$i<=$#port;$i++){
         				push(@string,"$inout [:] $port[$i]");
							}
						}
					else{
        				push(@string,"$inout [:] $in_out_string");
						}
					}
				}
			}
		if ($line=~/\);/ and $if_flag==1){$if_flag=2;}
#		print "results : \n@string\n";
		return (\@string,$parameter_flag,$if_flag);
		}

sub get_ASC_tree_file{
	my ($tree_file,$grbg)=@_;
	my @file_lines;
	open FILE ,$tree_file or die "**Error -- There is no such tree file $tree_file : $!\n";
	while(<FILE>){
		if ($_=~/^\s*$/){next;}
		if ($_=~/^\s*#/){next;}		
		if ($_=~/-synthesis/){next;}		
		if ($_=~s/-grbg// and !$grbg){next;}		
		my $next_flag = 0;
		foreach my $modules_flag (@NOFLAGS){
			if ($_=~/-$modules_flag/){$next_flag=1;last;}		
			}
		if ($next_flag){next;}
		chomp($_);
		$_=~s/#.*//;
		push(@file_lines,$_);
		}
	close(FILE);
	return @file_lines;
	}

sub check_file_result{
	my ($module,$module_file)=@_;
	if (exists $tree{'instance_module_name'}{$module}){
		my $file_name=file_name_processor_ASC($tree{'instance_module_name'}{$module},\@file_name,($mem_type eq "hash")); 
		if (check_file_result($file_name,$tree{'instance_module_name'}{$module})){
		 	return 0;
			}
	 	}
	elsif ($module eq $module_file){
		print "**Error -- there is no such file $module(_behavioral.v|_struct.v|.v)\n";
		exit(1);
		}
	return 1;
	}

sub get_ASC_next_number{
	my ($string)=@_;
	$string=~/\s*(\d+)\)/;
	return $1;
	}

sub remove_special_marks{
	my ($string)=@_;
	$string=~s/=$//;
	return $string;
	}

sub remove_spaces{
	my ($string)=@_;
	$string=~s/\s+//g;
	return $string;
	}
	
sub remove_functions{
	my ($line)=@_;
	if ($line=~/\bfunction\b/){
		while ($line=<FILE>){
			if ($line=~/\bendfunction\b/){last;}
			}
		}
	return $line;
	}
sub remove_tasks{
	my ($line)=@_;
	if ($line=~/\btask\b/){
		while ($line=<FILE>){
			if ($line=~/\bendtask\b/){last;}
			}
		}
	return $line;
	}
	
sub remove_sv_clocking{
	my ($line)=@_;
	if ($line=~/^\s*\bclocking\b/){
		while ($line=<FILE>){
			if ($line=~/\bendclocking\b/){last;}
			}
		}
	return $line;
	}

sub print_port_mismatch_size{
	my ($inout)=@_;
	my @results;
	if ($mem_type ne "hash"){
		@results=`grep -i "\\b$inout\\b" *.ASC`;
		}
	else{
		@results = get_all_arrays($inout_hash_port{$inout});
		}
	foreach my $result (@results){
		if ($result=~/\s*(\w+)\.ASC\s*:\s*(input|output|inout)\s+\[(\d*):\d*\]\s+(\w+)\s+(\S+)\s+\/\/.*/){
			my $instance=$1; 
			my $size=($3 ne "") ? $3 : 0; 
			my $input_output =$2; 
			if ($inout ne $5){next;}
#			print LOG "Instance : $instance $input_output port $inout size ".($size+1)."\n";
			}
		}
	}

sub print_port_output_results{
	my ($inout)=@_;
	my @results;
	if ($mem_type ne "hash"){
		@results=`grep -i "\\b$inout\\b" *.ASC`;
		}
	else{
      @results= get_all_arrays($inout_hash_port{$inout});
		}
	foreach my $result (@results){
		if ($result=~/\s*(\w+)\.ASC\s*:\s*(input|output|inout)\s+\[(\d*):\d*\]\s+(\w+)\s+(\S+)\s+\/\/.*/){
			my $instance=$1; 
			if ($2 eq 'input'){next;}
			if ($inout ne $5){next;}
			print LOG "Instance : $instance output port $4 wire $inout\n";
			}
		}
	}

sub check_line_ASC{
	my ($line)=@_;
	if ($line=~/^\s*$/){
		return 1;
		}
	elsif ($line=~/^\s*\/\//){
		return 1;
		}
	elsif ($line=~/^\s*--/){
		return 1;
		}
	return 0;
	}

sub check_endmodule_ASC{
	my ($line)=@_;
        if ($line=~/^\s*endmodule/){
		return 1;
		}
	return 0;
	}

sub get_module_name{
	my ($line)=@_;
	if ($line=~/^\s*(module|program|interface)\s+(\w+)/){
	   my $if_addition = ($1 eq "interface") ? "-if" : "";
		return ($2, $if_addition);
		}
	return ("nomodule" , "");
	}

sub check_def_line{
	my ($line,$def_name,$def_flag,$define_conter_ptr)=@_;
	if ($line=~/`(ifdef|elsif)\s+$def_name/){
		$def_flag = 1;
		}
	elsif ($line=~/`(ifdef|elsif)\s+\w+/){
		$def_flag = 0;
		}
	elsif ($line=~/`else/){
		$def_flag = ($def_flag) ? 0 : 1;
		}
	elsif ($line=~/`endif/ and ${$define_conter_ptr} == 0){
		$def_flag = 1;
		}
	return $def_flag;
	}

sub change_ezfeed_ASC_file{
	my ($instance,$port)=@_;
	open FILE ,"$instance.ASC" or die "cannot open file :$instance.ASC : $!\n";
	open FILEOUT ,">$instance.ASC.tmp" or die "cannot open file :$instance.ASC.tmp : $!\n";
	while(<FILE>){
		$_=~s/($port\s+)$port/$1ezfeed_$port/;
		print FILEOUT $_;
		}
	close(FILE);
	close(FILEOUT);
	system("mv $instance.ASC.tmp $instance.ASC");
	}

sub check_modification{
		my ($change,$print2dir,$struct_name,$module_list_ptr)=@_;
		if ($change){
			if (-e "$print2dir/$struct_name"."_struct.v"){
				my $sb=stat("$print2dir/$struct_name"."_struct.v");
				my $modifaction_time=$sb->mtime;
				foreach my $instant (@{$module_list_ptr}){
					$file_name=file_name_processor_ASC($instant,\@file_name,($mem_type eq "hash")); # getting the module file name
					if (-e $file_name){
						$sb=stat("$file_name");
						if ($modifaction_time<$sb->mtime){
							return 0;
							}
						}
					else{
						return 0;
						}
					}
				}
			else{
				return 0;			
				}
			}
		else{
			return 0;
			}
		return 1;
		}

sub check_variable_definition{
	my ($var,$string)=@_;
	if (!(defined $var)){
		print "Error -- $string not defined!!!\n";
		exit(1);
		}
  }

sub get_all_arrays{
	my ($hash_ptr)=@_;
	my @array;
	foreach my $key (keys %{$hash_ptr}){
#	  foreach my $key2 (keys %{$hash_ptr{$key}}){
# 	   if (exists $hash_ptr{$key}{$key2}){
# 	     my $str = "$key.ASC: $hash_ptr{$key}{$key2}";
# 		  push(@array,$str);
# 		  }
#     }
 	   if (exists ${$hash_ptr}{$key}){
 	     my $str = "$key.ASC: ${$hash_ptr}{$key}";
 		  push(@array,$str);
 		  }
		}
	return @array;
	}

sub clean_wire_name{
	my ($wire)=@_;
	$wire=~s/=$//;
	return $wire;
	}

sub get_if_str{
	my ($struct_name)=@_;
	$struct_name=~s/_top/_test/;
	$struct_name .= " TC(";
	return $struct_name;
	}
