#!/usr/bin/env perl

use strict;
use warnings;

package setup_version_control;
use arguments_parser;
use Data::Dumper;
use File::Basename;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module


sub new{
    my $class = shift;
    my $self = {'vc_type' => shift , 'rep_dir' => shift ,
                'logger' => Log::Log4perl->get_logger() ,
                'rep_type_setup_dir' => dirname(__FILE__)."/repository_type_setup"};
    my $rep_type_setup_dir = $self->{'rep_type_setup_dir'};
    my $repository_type = $self->{'vc_type'};
    bless $self, $class;
    if (!defined $repository_type or !-e "$rep_type_setup_dir/$repository_type/$repository_type.pm"){
        $self->{'logger'}->error("Please specify a valid version control type");
        $self->{'logger'}->info("The current exists:");
        foreach my $vctype (`find $rep_type_setup_dir -maxdepth 1 -type d`){
            chomp($vctype);
            $self->{'logger'}->info(" ".basename($vctype));
        }        
        exit(1);
    }
    $self->setup_repository();
    return $self;
}

###############################################
# setup repository function should run the 
# setup repository script to generte the 
# initial version of the repository 
###############################################
sub setup_repository{
    my ($self)=@_;
    $self->{'logger'}->info("Running repository setup command for :".$self->{'vc_type'});
    my $setup_file = $self->{'rep_type_setup_dir'}."/".$self->{'vc_type'}."/".$self->{'vc_type'}.".pm";
    our $vc_cmd;
    if (!-e $setup_file){
        $self->{'logger'}->error("Did not find repository setup for ".$self->{'vc_type'});
    } else {
        require $setup_file;
        print "$setup_file\n";
        print Dumper($vc_cmd);
        $ENV{REPO_DIR} = $self->{'rep_dir'};
        if (system($vc_cmd->{'setup_cmd'}->{'cmd'})){
            $self->{'logger'}->error("Failed running $setup_file\n");
            exit(1);
        }
    }
}

sub main{
    my $arg_handler = arguments_parser->new();
    $arg_handler->add_arg('-repository','Repository location',{'default' => undef});
    $arg_handler->process(@ARGV);
    my $file_dir = dirname(__FILE__);
    # checking if defined environment variable for the version control
    if (!defined $ENV{'VERSION_CONTROL_TYPE'}){
        Log::Log4perl->error("Must specify the version type in the project setting!!!");    
        exit(1);
    }
    my $repository_type = $ENV{'VERSION_CONTROL_TYPE'};
    my $repository_dir = $arg_handler->{'arguments'}->{'-repository'}->{'val'};
    my $setup_version_control = setup_version_control->new($repository_type,$repository_dir);
}

1;
