#!/usr/bin/env perl

use strict;
use warnings;


package arguments_parser;
use Data::Dumper;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);
use Getopt::Long;
# to use this 

#The following package is getopt wrapper to give full support for arguments  
sub new{
    my $class = shift;
    my $return_not_exists = shift;
    my $self = {'_arg_ptr' => {}, 'return_not_exists' => $return_not_exists, 'args_array' => [],'head' => shift , 'logger' => get_logger()};
    bless $self, $class;
    return $self;
}

sub add_arg{
    my ($self,@inputs)=@_;
    my $arg_info = ($#inputs >= 2) ? pop(@inputs): {};
    my $description = pop(@inputs);
    my $arg = shift(@inputs);
    $self->{'arguments'}->{$arg} = $arg_info;
    $self->{'arguments'}->{$arg}->{'val'} = $arg_info->{'default'};
    $self->{'arguments'}->{$arg}->{'desc'} = $description;
    while (@inputs){
        my $extra_arg = shift(@inputs);
        $self->{'arguments'}->{$extra_arg} = $self->{'arguments'}->{$arg};
    }
}

sub get_arg{
    my ($self, $arg)= @_;
    return $self->{'arguments'}->{$arg}->{'val'};
}

sub process{
    my ($self,@arguments) = @_;
    my @not_exists = qw();
    for (my $i = 0 ; $i<=$#arguments ; $i++) {
        my $arg = $arguments[$i];
        if ($arg eq "-help" or $arg eq "--help" or $arg eq "-h") {
            $self->help("");
            exit(1);
        } elsif (not exists $self->{'arguments'}->{$arg}){
            if (defined $self->{'return_not_exists'}){
                push(@not_exists,$arg);
            } else {
                $self->{'logger'}->error("No such argument ".$arg);
            }
        } elsif (defined $self->get_arg_type($arg) and $self->get_arg_type($arg) eq "array"){
            for (my $j = ++$i ; $j<=$#arguments ; $j++,$i++){
                push(@{$self->{'arguments'}->{$arg}->{'val'}},$arguments[$i]);
                last if (not defined $arguments[$j+1] or $arguments[$j+1]=~/^\-/);
            }
        } elsif (defined $self->get_arg_type($arg) and $self->get_arg_type($arg) eq "bool"){
            $self->{'arguments'}->{$arg}->{'val'} = ($self->{'arguments'}->{$arg}->{'default'} == '0') ? '1' : '0';            
            push(@{$self->{'args_bool_array'}},$arg);
        } else {
            $self->{'arguments'}->{$arg}->{'val'} = $arguments[++$i];
        }
        push(@{$self->{'args_array'}},$arg);
    }
    return \@not_exists;
}

sub get_arg_type{
    my ($self,$arg)=@_;
    if (defined $self->{'arguments'}->{$arg}->{'type'}){
        return $self->{'arguments'}->{$arg}->{'type'};
    }
    return undef;
}

sub help{
    my ($self,$string)=@_;
    foreach my $arg (keys %{$self->{'arguments'}}){
        my $arg_type = $self->get_arg_type($arg);
        my $additionalStr = (!defined $arg_type) ? "<VALUE>" : ($arg_type eq 'array') ? "<VALUE> <VALUE> ..." : ""; 
        $self->{'logger'}->info($arg." ".$additionalStr.":\n\t".$self->{'arguments'}->{$arg}->{'desc'});
    }    
}


1;

