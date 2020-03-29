#!/usr/bin/env perl

use strict;
use warnings;

package block;
our $dirname;
our $common_dir;
use arguments_parser;
use Data::Dumper;
use file_list_functions;
use Log::Log4perl qw(:easy);
use FileHandle;
Log::Log4perl->easy_init($ERROR);

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module


sub new{
    my $class = shift;
    my $self = {'file_name' => shift , 'start' => shift, 'end' => shift, 'logger' => get_logger()};
    #check if file exists 
    bless $self, $class;
    return $self;
}

sub get_blocks{
    my ($self)=@_;
    my $fh = new FileHandle;
    $fh->open("<".$self->{'file_name'}) or die "cannot open file :".$self->{'file_name'}." : $!\n";
    my @start = @{$self->{'start'}};
    my @end = @{$self->{'end'}};
    while(<$fh>){
        #now need to go over the start regex to make sure everything is setup
        matches($fh,$_,\@start,\@end) 
        
    }
}


sub matches{
    my ($self,$fh,$start_ptr,$end_ptr)=@_;
    my $start_pos = $fh->getpos();
    foreach my @start (@{$start_ptr}){
        while (<$fh>){
            
        }    
}

sub match{
    my ($self,$fh,$start_ptr,$end_ptr)=@_;
    my @start_array = @{$start_ptr};
    my @end_array = @{$end_ptr};
    while (<$fh>){
        foreach 
        if ($_=~/
        
    }    
}


sub main{
}

1;
