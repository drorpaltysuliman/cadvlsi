#!/usr/bin/env perl

use strict;
use warnings;

package common_package;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use Storable qw(dclone);
Log::Log4perl->easy_init($INFO);

sub get_dir_content{
    my ($dir,$content)=@_;
    my %content;
    opendir FLOWDIR, $dir or die "cannot open dir $dir\n";
    my @flows_dir = readdir FLOWDIR;
    foreach my $file_dir (@flows_dir){
        next if $file_dir=~/^\.+$/;
        my $type = (-d "$dir/$file_dir") ? 'dir' : 'file';
        $content->{$type}{"$dir/$file_dir"} = 1;
    }
    close FLOWDIR;
    return \%content;
}


sub get_dir_files{
    my ($dir,$ptr)=@_;
    opendir my $fh, $dir or die "cannot open dir $dir\n";
    my @flows_dir = readdir $fh;
    foreach my $file_dir (@flows_dir){
        next if $file_dir=~/^\.+$/;
        my $type = (-d "$dir/$file_dir") ? 'dir' : 'file';
        $ptr->{$type}{"$dir/$file_dir"} = 1;
        if ($type eq 'dir'){
            get_dir_files("$dir/$file_dir",$ptr);
        }
    }
    close $fh;
}

sub get_recursive_dir_content{
    my ($dir)=@_;
    my %files_info;
    get_dir_files($dir,\%files_info);
    return \%files_info;
}

sub uniqulify_array{
    my (@array)=@_;
    my %uniquHash;
    my @newArray;
    foreach my $element (@array){
        push(@newArray,$element) if (!exists $uniquHash{$element});
        $uniquHash{$element} = 1;
    }
    return @newArray;
}

sub check_extension{
    my ($file,$extension_ptr)=@_;
    if (!-e $file){
        Log::Log4perl->get_logger()->error("No such file $file ...");
        return 0;
    } elsif (defined $extension_ptr and ref($extension_ptr) eq "ARRAY"){
        foreach my $ext (@{$extension_ptr}){
            if ($file=~/$ext$/){
                return 1;
            }
        }
    } else {
        Log::Log4perl->get_logger()->error("No extension array found ...");
        return 0;
    }
    return 0;

}

sub get_package_name{
    return caller();
}

sub run_system{
    my ($cmd)=@_;
    Log::Log4perl->get_logger()->info("Running system command $cmd ...");    
    if (system($cmd)){
        Log::Log4perl->get_logger()->error("Command $cmd Failed!!!");
    }
}

1;




