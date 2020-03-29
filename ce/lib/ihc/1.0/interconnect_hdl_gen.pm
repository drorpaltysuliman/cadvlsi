#!/usr/bin/env perl

use strict;
use warnings;

package interconnect_hdl_gen;
our $dirname;
our $common_dir;
use arguments_parser;
use Data::Dumper;
use file_list_functions;
use Log::Log4perl qw(:easy);
use parse_hdl;
Log::Log4perl->easy_init($ERROR);

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module


# global ptr
our $info_ptr;

sub new{
    my $class = shift;
    my $self = {'head' => shift , 'logger' => get_logger()};
    #check if file exists 
    if (defined $self->{'head'} and -f $self->{'head'}){
        include($self->{'head'});
    } else {
        $self->{'logger'}->error("No head file specified, please use -head <file> to read the filelist")
    }
    bless $self, $class;
    return $self;
}

sub get_hdl_information{
    my ($self)=@_;
    my $parse_hdl = parse_hdl->new();
    
}



sub main{
    my $arg_handler = arguments_parser->new();
    $arg_handler->add_arg('-top','Location of the top file module',{'default' => undef});
    $arg_handler->process(@ARGV);
}

1;
