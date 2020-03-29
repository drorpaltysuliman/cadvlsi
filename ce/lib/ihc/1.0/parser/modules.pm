#!/usr/bin/env perl

use strict;
use warnings;

package modules;
our $dirname;
our $common_dir;
use arguments_parser;
use Data::Dumper;
use file_list_functions;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module


sub new{
    my $class = shift;
    my $self = {'sv_file' => shift , 'logger' => get_logger()};
    #check if file exists 
    bless $self, $class;
    return $self;
}

sub get_modules_string{
    my ($self)=@_;
    
}

sub main{
}

1;
