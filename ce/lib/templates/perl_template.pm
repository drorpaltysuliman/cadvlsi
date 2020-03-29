#!/usr/bin/perl 

use strict;
use warnings;

package PACKAGE_NAME;
use arguments_parser;
use Data::Dumper;

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module

sub new{
    my $class = shift;
    my $self = {'args' => shift, 'pdf' => shift}; 
    bless $self, $class;
    return $self;
}



sub init{
    my ($self)=@_;
    my $arg_handler = arguments_parser->new();
    $arg_handler->add_arg('-pdf','PDF fiel to convert',{'default' => undef});
    $arg_handler->process(@ARGV);
    $self->{'args'} = $arg_handler->{'arguments'};
}


sub main{
    my $PACKAGE_NAME = PACKAGE_NAME->new();
    $PACKAGE_NAME->init();
}



my $pdf = CAM::PDF->new(
