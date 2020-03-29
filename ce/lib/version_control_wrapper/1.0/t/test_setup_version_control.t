#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;

# to be able to create a new repository
system("rm -rf test_results");
BEGIN{use_ok('setup_version_control')}

my $obj = setup_version_control->new('svn','test_results');
isa_ok($obj,'setup_version_control');
can_ok($obj,qw(setup_repository));
#isa_ok($ap,'arguments_parser');
#can_ok($ap,qw(add_arg get_arg process help));
#is($ap->get_arg('-head'),'ggg/hhh/lll.pl','check head val');

