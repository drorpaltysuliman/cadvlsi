#!/usr/bin/env perl

use strict;
use warnings;

package hdl_file_list;
use file_list_functions;
use arguments_parser;
use Data::Dumper;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module


# global ptr
our $info_ptr;
our $dirname;
our $common_dir;

sub new{
    my $class = shift;
    my $self = {'logger' => Log::Log4perl->get_logger()};
    bless $self, $class;
    return $self;
}


sub read_files{
    my ($self)=@_;
    #check if file exists 
    my $head_file = $self->{'args'}->{'-top_file_list'}->{'val'};
    if (defined $head_file and -f $head_file){
        include($head_file);
        return $info_ptr;
    }
    return undef;
    
}

sub print_file{
    my ($self)=@_;
    #check if file exists 
    my $res = $self->read_files();
    if (defined $res){
        my $file_list_name = $self->{'args'}->{'-o'}->{'val'};
        open FILE ,">$file_list_name" or die "cannot open file $file_list_name : $!\n";
        foreach my $file (keys %{$info_ptr->{'filelist'}}){
            if ($info_ptr->{'filelist'}->{$file}->{'execute'} eq "vfile"){
                print FILE "-v ";
            } elsif ($info_ptr->{'filelist'}->{$file}->{'execute'} eq "yfile"){
                print FILE "-y ";
            } 
            print FILE "$file\n";
        }
        close(FILE);
    } else {
        $self->{'logger'}->error("No head file specified, please use -top_file_list <file> to read the filelist")
    }
    

}

sub split_var{
    my($self,$var)=@_;
    if ($var=~/(\w+)=(\w+)/){
        return $1,$2;
    } elsif ($var=~/^\w+$/){
        return $var,1;                       
    }
    $self->{'logger'}->error("Illegal var is set $var, it must be <key>=<value> or <key> (only letters and numbers are allowed");
    exit(1);
}

sub set_vars{
    my ($self)=@_;
    my @var_array = @{$self->{'args'}->{'-var'}->{'val'}} if defined $self->{'args'}->{'-var'}->{'val'};
    my %vars = {};
    foreach my $var (@var_array){
        my ($key,$value) = $self->split_var($var);
        $ENV{$key} = $value;
    } 
}

sub init{
    my ($self)=@_;
    my $arg_handler = arguments_parser->new();
    $arg_handler->add_arg('-top_file_list','Location of the head file to read',{'default' => undef});
    $arg_handler->add_arg('-o','specify output file list name',{'default' => undef});
    $arg_handler->add_arg('-var','specify file list file name',{'type' => 'array' , 'default' => undef});
    $arg_handler->add_arg('-order','print file list according to order',{'type' => 'bool','default' => 0});
    $arg_handler->process(@ARGV);
    $self->{'args'} = $arg_handler->{'arguments'};
}


sub main{
    my $hdl_file_list = hdl_file_list->new();
    $hdl_file_list->init();
    $hdl_file_list->set_vars();    
    $hdl_file_list->print_file();
}

1;
