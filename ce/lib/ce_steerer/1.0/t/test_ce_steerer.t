#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;
use Data::Dumper;

BEGIN{use_ok('ce_steerer')}

can_ok('ce_steerer','new');
my $test_obj = ce_steerer->new('dummy');
isa_ok($test_obj,'ce_steerer');
can_ok($test_obj,qw(get_versions_table set_perl5lib_var set_env));
$test_obj->set_perl5lib_var();
$test_obj->set_env();
is($ENV{'CONFIG_PARSER'},'1.0','check config parser environment variable variable');
is($ENV{'HDL_FILE_LIST'},'1.0','check config parser environment variable variable');
is($test_obj->validate_tool_info($test_obj->{'tools_info'},"dummy_tool",'ver'),0);
is($test_obj->validate_tool_info($test_obj->{'tools_info'},"hdl_file_list",'ver'),1);
