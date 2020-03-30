#!/usr/bin/env perl

#use strict;
use warnings;

package version_control_wrapper;
use lib "$ENV{'CE_HOME'}/lib/perl_packages/$ENV{'PERL_PACKAGES'}/JSON/lib/perl5";
use arguments_parser;
use common_package;
use Data::Dumper;
use file_list_functions;
use File::Basename;
use JSON;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module

sub new{
    my $class = shift;
    our $vc_cmd;
    my $vct = $ENV{'VERSION_CONTROL_TYPE'};
    my $self = {'vc_type' => $vct , 'rep_dir' => $ENV{'REPO_DIR'} ,
                'logger' => Log::Log4perl->get_logger() ,
                'rep_type_setup_dir' => dirname(__FILE__)."/repository_type_setup"};
    my $setup_file = $self->{'rep_type_setup_dir'}."/".$vct."/".$vct.".json";
    $self->{'config'} = JSON::from_json(`cat $setup_file`);
    bless $self, $class;
    return $self;
}

# this function suppose to convert directories to files so all 
# file base version contro will not have to specify all files.
sub extract_cmd{
    my ($self,$arguments_ptr)=@_;
    my $file_ptr = {};
    foreach my $arg (@{$arguments_ptr}){
        continue if !defined $arg;
        if (-d $arg){
            if ($self->{'config'}->{'vc_setup'}->{'type'} eq "file"){
                $file_ptr = common_package::get_recursive_dir_content($arg);
            } else {
                $file_ptr->{'dir'}->{$arg} = 1;
            }
        } elsif (-f $arg){
            # add the file to the ptr 
            $file_ptr->{'file'}->{$arg} = 1;
        } else {
            $self->{'logger'}->error("Unrecognized argumnet $arg, skipping...");
        }
    }
    $self->{'file_ptr'} = $file_ptr;
}


sub submit{
    my ($self)=@_;
    my $config = $self->{'config'}->{'submit'};
    my $submit_cmd = $config->{'cmd'};
    my $message_arg = $config->{'args'}->{'message'};
    my $message_descr = $self->{'arg_handler'}->{'arguments'}->{'-m'}->{'val'};
    my $arg_space = (exists $config->{'args_type'} and $config->{'args_type'} eq "nospace") ? "" : " ";
    # make sure a message is entered
    if (!defined $message_descr or $message_descr eq ''){
        $self->{'logger'}->error("Please enter a message using -m argument");
        exit(1);
    } 
    if ($self->{'config'}->{'vc_setup'}->{'type'} eq "file"){
        foreach my $file (keys %{$self->{'file_ptr'}->{'file'}}){
            common_package::run_system("$submit_cmd $message_arg$arg_space\"$message_descr\" $file");
        }
    } else {
        common_package::run_system("$submit_cmd $message_arg \"$message_descr\" ");
    }
}

sub common_exec{
    my ($self,$name)=@_;
    if ($self->{'config'}->{'vc_setup'}->{'type'} eq "file"){
        foreach my $file (keys %{$self->{'file_ptr'}->{'file'}}){
            my $sync_cmd = $self->{'config'}->{$name}->{'cmd'};
            common_package::run_system("$sync_cmd $file");
        }
    }
}


sub sync{
    my ($self)=@_;
    common_exec($self,"sync")
}

sub add{
    my ($self)=@_;
    common_exec($self,"add")
}

sub revert{
    my ($self)=@_;
    common_exec($self,"revert")
}

sub delete{
    my ($self)=@_;
    common_exec($self,"delete")
}


sub run_func{
    my($self,$function)=@_;
    if (defined $function and eval {$function}){
        return $function->($self);
    } else {
        $self->{'logger'}->error("Version Control cmd not valid, valid commands are:");
        $self->{'logger'}->error("  vcw submit");
        $self->{'logger'}->error("  vcw sync");
        exit(1);
    }
}

sub init{
    my ($self)=@_;
    my $arg_handler = arguments_parser->new('return_not_exists');
    $arg_handler->add_arg('submit','Use submit to submit files',{'default' => '0', 'type' => "bool"});
    $arg_handler->add_arg('sync','Use sync to update your directory',{'default' => '0','type' => "bool"});
    $arg_handler->add_arg('add','Use add to add new file',{'default' => '0','type' => "bool"});
    $arg_handler->add_arg('revert','Use revert to refresh to repository revision',{'default' => '0','type' => "bool"});
    $arg_handler->add_arg('delete','Use delete to remove file from repository',{'default' => '0','type' => "bool"});
    $arg_handler->add_arg('-m','Add a massage to the version control',{'default' => undef});
    $self->{'floating_args'} = $arg_handler->process(@ARGV);
    $self->{'arg_handler'} = $arg_handler;
}


sub main{
    my $version_control_wrapper = version_control_wrapper->new();
    $version_control_wrapper->init();
    my $function_name = ${$version_control_wrapper->{'arg_handler'}->{'args_bool_array'}}[0];
    $version_control_wrapper->extract_cmd($version_control_wrapper->{'floating_args'});
    $version_control_wrapper->run_func($function_name);
}

1;
