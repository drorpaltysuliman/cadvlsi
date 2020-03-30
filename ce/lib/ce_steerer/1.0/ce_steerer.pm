#!/usr/bin/perl -w

use strict;
use warnings;

package ce_steerer;
BEGIN{
use lib "$ENV{'CE_HOME'}/lib/common";
use lib "$ENV{'CE_HOME'}/lib/perl_packages/$ENV{'PERL_PACKAGES'}/JSON/lib/perl5";
}
use File::Basename;
use JSON; 
use Log::Log4perl qw(:easy);
use Data::Dumper;
use arguments_parser;
use common_package;
Log::Log4perl->easy_init({  level   => $DEBUG,
                            file    => '>>ce_steerer.log',
                            filemode    => 'w',
                            layout  => '%d-%F-%M- %m%n'},
                         {  level   => $DEBUG,
                            file    => 'STDOUT',
                            layout  => '%d- %m%n'});

__PACKAGE__->main() unless caller;


sub new{
    my ($class,$project)=@_;
    my $self = {'project' => $project , 'proj_info' => {} , 'logger' => get_logger(), 'dirname' => dirname(__FILE__)};
    bless $self,$class;
    $self->get_versions_table();
    return $self;
}

sub get_versions_table{
    my ($self)=@_;
    my $conf_file = (defined $self->{'project'} and
                        -f $self->{'dirname'}."/../../../projects/".$self->{'project'}.".json") ?
                        $self->{'dirname'}."/../../../projects/".$self->{'project'}.".json" :
                        (-f $self->{'dirname'}."/projects/".$self->{'project'}.".json") ?
                        $self->{'dirname'}."/projects/".$self->{'project'}.".json" :
                        undef;
    if (not $conf_file){
        $self->{'logger'}->error("No such project ".$self->{'project'});
        exit(1);
    }
    my $json_str = `cat $conf_file`;
    $self->{'proj_info'} = eval { JSON::from_json($json_str) };
    $self->{'logger'}->error("Failed to read project ".$self->{'project'}." JSON file") and exit(1) if ($@);
    $self->{'tools_info'} = $self->{'proj_info'}->{'tools'};
    #setting EXTERNAL_TOOLS
    $ENV{'EXTERNAL_TOOLS'} = "$ENV{'CE_HOME'}/external_tools" if (-d "$ENV{'CE_HOME'}/external_tools");
}

sub validate_tool_info{
    my ($self,$hash_ptr,$tool_name,$key_name)=@_;
    if (ref($self->{'tools_info'}->{$tool_name}) eq 'HASH' 
        and exists $self->{'tools_info'}->{$tool_name}->{$key_name}){
        return 1;
    } 
    return 0;

}


sub set_env_var{
    my ($self,$var_val_hash)=@_;
    #Environmnet variables to set in tools
    while( my ($var,$value) = each %{$var_val_hash}){
        while ($value=~/\$ENV{(\w+)}/){
            my $env = $1;
            if (defined $ENV{$env}){
                $value=~s/\$ENV{(\w+)}/$ENV{$env}/;
            } else {
                $self->{'logger'}->error("No environnmet variable $env found!!!");
                exit(1);                
            }
        }
        if ($var=~/concat\(\s*(\w+)\s*,(\S+)\)/){
            $self->concat_path_var($1,$value,$2);
        } else {
            $ENV{uc($var)} = $value;
        }
    }
}


sub set_env{
    my ($self)=@_;
    #set global environment variables
    foreach my $var (@{$self->{'proj_info'}->{'env'}}){
        #Environmnet variables to set in tools
        $self->set_env_var($var);
    }    
    #set environment variables in tools
    foreach my $tool_name (keys %{$self->{'tools_info'}}){
        if ($self->validate_tool_info($self->{'tools_info'},$tool_name,'ver')){
            $ENV{uc($tool_name)} = $self->{'tools_info'}->{$tool_name}->{'ver'};
        } else {
            $self->{'logger'}->error("No version specified for $tool_name");
        }
        #Environmnet variables to set in tools
        if ($self->validate_tool_info($self->{'tools_info'},$tool_name,'set')){
            foreach my $var (@{$self->{'tools_info'}->{$tool_name}->{'set'}}){
                $self->set_env_var($var);
            }
        }
    }
}


sub set_perl5lib_var{
    my ($self)=@_;
    if (!defined $ENV{'CE_HOME'}){
        $self->{'logger'}->error("No 'CE_HOME' variable definition");
        return;
    }
    my @perl5lib_str = ("$ENV{'CE_HOME'}/lib/common");
    foreach my $tool_name (keys %{$self->{'tools_info'}}){
        if ($self->validate_tool_info($self->{'tools_info'},$tool_name,'ver')){
            push(@perl5lib_str , "$ENV{'CE_HOME'}/lib/$tool_name/".$self->{'tools_info'}->{$tool_name}->{'ver'});
            my $common_dir = "$ENV{'CE_HOME'}/lib/$tool_name/".$self->{'tools_info'}->{$tool_name}->{'ver'}."/common";
            if (-d $common_dir){
                push(@perl5lib_str , $common_dir);
            }
        } else {
            $self->{'logger'}->error("No version specified for $tool_name");
        }
    }
    # uniqulify PERL5LIB 
    my $perl_5_lib_str = (exists($ENV{'PERL5LIB'})) ? ":".$ENV{'PERL5LIB'} : "";
    $ENV{'PERL5LIB'} = uniqulify_string(join(":",@perl5lib_str).$perl_5_lib_str,":");
}


sub set_path_var{
    my ($self)=@_;
    if (!defined $ENV{'CE_HOME'}){
        $self->{'logger'}->error("No 'CE_HOME' variable definition");
        return;
    }
    my @path = ("$ENV{'CE_HOME'}/bin");
    # get all external path
    chomp(my @ext_path = (defined $ENV{'EXTERNAL_TOOLS'}) ? `find $ENV{'EXTERNAL_TOOLS'} -name bin -type d` : []);
    # uniqulify PERL5LIB 
    push(@path,split(":",$ENV{'PATH'})) if (defined $ENV{'PATH'});
    my @uniq_array = common_package::uniqulify_array(@path);
    $ENV{'PATH'} = uniqulify_string(join(":",@path).":".join(":",@ext_path).":".$ENV{'PATH'},":") if @uniq_array;
}

sub concat_path_var{
    my ($self,$var,$value,$delimiter)=@_;
    my @values = ($value);
    push(@values,split($delimiter,$ENV{$var})) if (defined $ENV{$var});
    my @uniq_array = common_package::uniqulify_array(@values);
    $ENV{$var} = join($delimiter,@uniq_array) if @uniq_array;
}

sub uniqulify_string{
    my ($string,$delimiter)=@_;
    my @values = split($delimiter,$string);
    return join($delimiter,common_package::uniqulify_array(@values));
    
}
sub main{
    my $arg_handler = arguments_parser->new();
    $arg_handler->add_arg('-project','Project name',{'default' => undef});
    $arg_handler->add_arg('-shell_type','Project name',{'default' => "bash"});
    $arg_handler->add_arg('-sim','Project name',{'type' => 'bool', 'default' => 0});
    $arg_handler->process(@ARGV);
    my $ce_steerer = ce_steerer->new($arg_handler->{'arguments'}->{'-project'}->{'val'});
    $ce_steerer->set_perl5lib_var();
    $ce_steerer->set_env();
    $ce_steerer->set_path_var();
    $ce_steerer->{'logger'}->info("Creating new ".$arg_handler->{'arguments'}->{'-shell_type'}->{'val'}." for project ".$arg_handler->{'arguments'}->{'-project'}->{'val'});
    if (!$arg_handler->{'arguments'}->{'-sim'}->{'val'}){
        system($arg_handler->{'arguments'}->{'-shell_type'}->{'val'});
        $ce_steerer->{'logger'}->info("Exit project ".$arg_handler->{'arguments'}->{'-project'}->{'val'});
        }

        
}
