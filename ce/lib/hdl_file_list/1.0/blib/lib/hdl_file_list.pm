#!/usr/bin/env perl

use strict;
use warnings;


BEGIN{
use File::Basename;
our $dir_name = dirname(__FILE__);
our $common_dir = dirname(dirname(__FILE__));
# This part is to take the right common from ce directory
push(@INC,$common_dir."/common");
push(@INC,$dir_name."/common");
}

package hdl_file_list;
our $dirname;
our $common_dir;
use arguments_parser;
use Data::Dumper;
use file_list_functions;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module


# global ptr
our $infoPtr;

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

sub file_list_handle{
    my ($self)=@_;
    print STDERR Dumper($infoPtr);
}

sub main{
    my $arg_handler = arguments_parser->new();
    $arg_handler->add_arg('-head','Location of the head file to read',{'default' => undef});
    $arg_handler->process(@ARGV);
    my $hdl_file_list = hdl_file_list->new($arg_handler->{'arguments'}->{'-head'}->{'val'});
    
    }

1;
