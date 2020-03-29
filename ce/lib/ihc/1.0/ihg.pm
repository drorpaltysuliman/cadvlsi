#!/usr/bin/perl 

use strict;
use warnings;

package ihg;
use arguments_parser;
use hdl_file_list;
use Data::Dumper;
use parse_hdl;
use gen_hdl;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);


__PACKAGE__->main() unless caller; # executes at run-time, unless used as module

sub new{
    my $class = shift;
    my $self = {'logger' => get_logger(),
                'tree_level' => {},
                'modules_structure' => {},
                'modules_files' => {},
                'top_modules' => []}; 
    bless $self, $class;
    $self->setup_env_vars();
    return $self;
}

sub setup_env_vars{
    my ($self)=@_;
    my %hash = ('IHG_RUN' => 'ON');
    foreach my $env_name (keys %hash){
        $ENV{$env_name} = $hash{$env_name};
    }
}


sub get_file_list{
    my ($self)=@_;
    my $hfl_obj = hdl_file_list->new();
    $hfl_obj->{'args'} = $self->{'args'};
    $self->{'file_list_info'} = $hfl_obj->read_files();
}


sub parse_files{
    my ($self)=@_;
    foreach my $file (keys %{$self->{'file_list_info'}->{'filelist'}}){
        $self->{'logger'}->info("Parsing $file ...");
        $self->{'parsed'}->{$file} = parse_hdl->new();
        $self->{'parsed'}->{$file}->read_file($file);
    }
}

sub get_tree_levels{
    my ($self,$top_name,$module,$level)=@_;
    $self->{'tree_level_max'}->{$top_name} = (not defined $self->{'tree_level_max'}->{$top_name} or $level > $self->{'tree_level_max'}->{$top_name}) ? $level : $self->{'tree_level_max'}->{$top_name};
    my @top_children = @{$self->{'modules_structure'}->{$module}};
    $self->check_tops(\@top_children);
    @{$self->{'tree_level'}->{$top_name}->{$level}->{$module}} = @top_children;
    foreach my $top (@top_children){
        my @top_modules = @{$self->{'modules_structure'}->{$top}};
        next if not @top_modules;
        get_tree_levels($self,$top_name,$top,$level+1);
   }
}


sub get_top_modules{
    my ($self)=@_;
    my %modules;
    $self->{'logger'}->info("Looking for top modules ...");
    foreach my $file (keys %{$self->{'parsed'}}){
        if (exists $self->{'parsed'}->{$file} and exists $self->{'parsed'}->{$file}->{'module'}){
            foreach my $module (keys %{$self->{'parsed'}->{$file}->{'module'}}){
                next if (exists $self->{'modules_structure'}->{$module});
                my @in_modules = (keys %{$self->{'parsed'}->{$file}->{'module'}->{$module}->{'modules'}});
                if (exists $self->{'modules_files'}->{$module}){
                    $self->{'logger'}->error("Module $module in $file already exists in ".$self->{'modules_files'}->{$module}."!!!Exit");
                    exit(1);
                }
                $self->{'modules_structure'}->{$module} = \@in_modules;
                $self->{'modules_files'}->{$module} = $file;
                foreach my $in_module (keys %{$self->{'parsed'}->{$file}->{'module'}->{$module}->{'modules'}}){
                    $modules{$in_module} = $module;
                }
            }
        }
    }
    foreach my $module (keys %{$self->{'modules_structure'}}){
        if (not exists $modules{$module}){
            push(@{$self->{'top_modules'}},$module);
        }
    }
    $self->{'logger'}->info("Found top modules: ".join(",",@{$self->{'top_modules'}}));
    return @{$self->{'top_modules'}};
}

sub build_top_ihg_files{
    my ($self,$top)=@_;
    if (not exists $self->{'tree_level_max'}->{$top}){
        $self->{'logger'}->error("Did not find top $top, exiting!!!\n");
        exit(1);
    }
    foreach my $level (reverse(0..$self->{'tree_level_max'}->{$top})){
        foreach my $module_to_build (keys %{$self->{'tree_level'}->{$top}->{$level}}){
            $self->{'logger'}->info("Generating $module_to_build\n");
            # module file 
            my $module_file = $self->{'modules_files'}->{$module_to_build};
            # get parsed info
            my $file = $self->{'modules_files'}->{$module_to_build};
            #print STDERR Dumper($self->{'parsed'}->{$file});
#            foreach my $module (@{$self->{'modules_structure'}->{$module_to_build}
        }
    }
}

sub check_tops{
    my ($self,$tops_ptr)=@_;
    if (defined $tops_ptr){
        foreach my $top (@{$tops_ptr}){
            if (not exists $self->{'modules_structure'}->{$top}){
                $self->{'logger'}->error("Did not find top $top in the current structure");
                $self->{'logger'}->error("Please Check if it exists in the filelist!!!");
                exit(1);
            }
        }
    }
}

sub check_module_exists{
    my ($self,$module)=@_;
    if (not exists $self->{'modules_files'}->{$module}){
        $self->{'logger'}->error("Did not find module $module in the current parsed information");
        $self->{'logger'}->error(" Check if it exists in the filelist!!!");
        exit(1);
    }
}

sub build_ihg_files{
    my ($self,$top)=@_;
    my $max_level = $self->{'tree_level_max'}->{$top};
    $self->{'logger'}->info("Depth heirarchy found $max_level ..."); 
    for (my $i=$max_level;$i != 0; $i=$i-1){
        foreach my $top_to_gen (keys %{$self->{'tree_level'}->{$top}->{$i}}){
            next if not $self->{'tree_level'}->{$top}->{$i}->{$top_to_gen};
            $self->{'logger'}->info("Gen module HDL $top_to_gen ...");
            my $gen_hdl = gen_hdl->new($self->{'file_list_info'},$self->{'modules_files'});
            $gen_hdl->parse_files($top_to_gen);
            $gen_hdl->build_module($top_to_gen);
        }
    }
}

sub init{
    my ($self)=@_;
    my $arg_handler = arguments_parser->new();
    $arg_handler->add_arg('-top_file_list','Location of the head file to read',{'default' => undef});
    $arg_handler->add_arg('-top','Provide top module',{'default' => undef});
    $arg_handler->add_arg('-skip_top_check','Check top level provided is in the tops found in the design',{'default' => undef});
    $arg_handler->process(@ARGV);
    $self->{'args'} = $arg_handler->{'arguments'};
}

sub main{
    my $ihg = ihg->new();
    $ihg->init();
    # reading files from config files
    $ihg->get_file_list();
    # Parse list files
    $ihg->parse_files();
    # get top level module
    my @top_array = ($ihg->{'args'}->{'-top'}->{'val'});
    # figuring out the strcture of the design
    $ihg->get_top_modules();
#    foreach my $top ($ihg->get_top_modules()){
    foreach my $top (@top_array) {
        $ihg->check_module_exists($top);
        # get the strcucture to build
        $ihg->get_tree_levels($top,$top,1);
        # build modules
        $ihg->build_ihg_files($top);
    }

}



