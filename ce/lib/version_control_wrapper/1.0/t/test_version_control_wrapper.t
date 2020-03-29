#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;
use Data::Dumper;

BEGIN{use_ok('version_control_wrapper')}

my $hfl = version_control_wrapper->new();
my ($arg_handler,$floating_args) = $hfl->init();
can_ok($hfl,qw(submit extract_cmd));
my @directory_to_extract = qw(t);
$hfl->extract_cmd(\@directory_to_extract);
is(join(' ',keys $hfl->{'file_ptr'}->{'file'}),'t/test_version_control_wrapper.t t/test_setup_version_control.t','check return val');
# check if the argument is bad
my @arg_to_check = ['bla'];
is(Dumper($hfl->extract_cmd(\@arg_to_check)),Dumper({}));
# check run_func
$hfl->run_func('submit',$arg_handler,);
is($hfl->run_func('submit',$arg_handler,),'')
