#!/usr/bin/env perl

use strict;
use warnings;
# logging packages
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);
#The following package includes all APIs to add file/dir to a specific file list 
use common_package;
# define ptr
our $info_ptr;
# counter to save the order 
our $counter = 1;

#########################
# run_checks 
# input : $checkToRun -> specify the key that includes all checks
# input : @arguments -> what ever arguments it is getting 

sub run_checks{
    my ($checkToRun,@arguments) = @_;
    if (exists $info_ptr->{'checks'}->{$checkToRun}){
        for my $func (keys %{$info_ptr->{'checks'}->{$checkToRun}}){
            $func->(@arguments)
        }
    }
}

sub get_fr_string{
    my ($file)=@_;
    my $ihg_file = find_replace_exe($file);
    if ($ihg_file ne $file){
        return $ihg_file;
    }
    return undef;
}


#########################
# add_file 
# input : $file -> the name of the file needed to be added to the filelist 
# Description : This function should add single file to the file list

sub add_file{
    my ($file) = @_;
    # run checks hooks if needed by the customer
    run_checks('add_file',$file);
    # can specify the type of the file - optional type file and library
    $info_ptr->{'filelist'}->{$file} = {'type' => 'file' , 'order' => $counter++, 'execute' => 'file', 'fr' => get_fr_string($file)};
}

#########################
# add_vfile 
# input : $file -> the name of the file needed to be added to the filelist 
# Description : This function should add single file to the file list

sub add_vfile{
    my ($file) = @_;
    # run checks hooks if needed by the customer
    run_checks('add_vfile',$file);
    # can specify the type of the file - optional type file and library
    $info_ptr->{'filelist'}->{$file} = {'type' => 'vfile' , 'order' => $counter++, 'execute' => 'vfile'};
}

#########################
# add_files
# input : $dir -> the name of the directory we want to add
# Description : This function should add all files in the directory with the right extension

sub add_files{
    my ($dir)=@_;
    run_checks('add_files',$dir);
    opendir DIR ,$dir or die "Cannot open dir $dir : $!\n";
    my @files = readdir DIR;
    foreach my $file (@files){
        next if ($file=~/^\./);
        # need to add recursive option as well.
        if (-d "$dir/$file"){
            add_files("$dir/$file");
        } elsif (check_extension($file,$info_ptr->{'extensions'})){
            $info_ptr->{'filelist'}->{"$dir/$file"} = {'type' => 'file' , 'order' => $counter++, 'execute' => 'files','fr' => get_fr_string($file)};            
        }
    }
}

#########################
# add_dir 
# input : $dir -> the name of the directory we want to add
# Description : This function should add all files in the directory with the right extension

sub add_ydir{
    my ($dir)=@_;
    run_checks('add_ydir',$dir);
    $info_ptr->{'filelist'}->{$dir} = {'type' => 'ydir' , 'order' => $counter++,, 'execute' => 'ydir'};            
}

#########################
# add_dir 
# input : $dir -> the name of the directory we want to add
# Description : This function should add all files in the directory with the right extension

sub add_ext{
    my ($ext)=@_;
    run_checks('add_ext',$ext);
    push(@{$info_ptr->{'extensions'}},$ext);            
}

#########################
# include 
# input : $fl_file -> file to include 
# Description : This function is designed to include other filelist files

sub include{
    my ($file)=@_;
    run_checks('include',$file);
    require $file;
}

#########################
# include 
# input : $fl_file -> check_path 
# Description : Internal check to verify oath of a file or directory

sub check_path{
    my ($dir)=@_;
    return (-e $dir) ?  1 : 0;
}

#########################
# include 
# input : $fl_file -> replace string 
# Description : This function is designed to include other filelist files

sub find_replace{
    my ($find,$replace)=@_;
    if (exists $ENV{'IHG_RUN'} and $ENV{'IHG_RUN'} eq "ON"){
        push(@{$info_ptr->{'replace'}},{$find => $replace});
    }
}

#########################
# find_replace_exe 
# input : $path
# Description : this function replace all information in the directory if exists

sub find_replace_exe{
    my ($path)=@_;
    foreach my $find_replace_hash (@{$info_ptr->{'replace'}}){
        my ($find,$replace) = %{$find_replace_hash};
        $path=~s/\b$find\b/$replace/;
    }
    return $path;
}




1;
