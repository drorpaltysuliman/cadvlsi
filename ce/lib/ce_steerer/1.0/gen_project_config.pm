#!/usr/bin/perl -w

use strict;
use warnings;

package gen_project_config;
use lib "$ENV{'CE_HOME'}/lib/common";
use File::Basename;
use common_package;

__PACKAGE__->main() unless caller;


our $versions_info_dir = dirname(__FILE__);

sub new{
    my ($class,$dir)=@_;
    my $self = bless {'ce_dir' => $dir} , $class;
    return $self;
}

sub get_flows_info{
    my ($self)=@_;
    my $ce_dir = $self->{'ce_dir'};
    my $dir_content = get_dir_content("$ce_dir/lib");
    my @flows = keys %{$dir_content->{'dir'}};
    return join(":",@flows);
}

sub main{
}
