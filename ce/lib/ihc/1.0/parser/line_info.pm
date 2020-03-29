#!/usr/bin/env perl

use strict;
use warnings;

package line_info;
use arguments_parser;
use FileHandle;
use Data::Dumper;
use file_list_functions;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module


sub new{
    my $class = shift;
    my $self = {'file_handle' => shift , 'logger' => get_logger()};
    #check if file exists 
    bless $self, $class;
    return $self;
}

sub get_line_info{
    my ($self)=@_;
    my $fh = $self->{'file_handle'};
    print STDERR "kkkkkk ".$fh->getpos();
    return $fh->getpos();
}

sub main{
}

1;
