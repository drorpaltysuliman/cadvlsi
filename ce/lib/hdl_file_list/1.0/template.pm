#!/usr/bin/perl -w
use file_list_functions;
use File::Basename;

my $current_dir = dirname(__FILE__);

###################################
# to add extensions to the file
# add_ext(".v");

###################################
# to add a define use the following
# <define name> : as you want to define 
# in the file +define+<define name>
# <value> : optional, if you want to have
# +define+<define name>=<value>
# add_define(<define name>[, <value>]);

###################################
# to add a file use the following
# <file>: location of the file needed
# add_file(<file>);

###################################
# to add a -v <file> use
# <file> : file location
# add_vfile(<file>);

###################################
# to add a -y use the following
# <dir> : dir location to add
# add_ydir(<dir>);

###################################
# to add an include 
# <file list file> : if you want to read a 
# different filelist in a different 
# block, use include function
# include(<file list file>);

