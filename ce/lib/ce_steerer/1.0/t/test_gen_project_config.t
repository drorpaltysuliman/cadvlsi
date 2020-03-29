#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;

BEGIN{use_ok('gen_project_config')}

can_ok('gen_project_config','new');

my $test_obj = gen_project_config->new("/home/cad_vlsi/cad_vlsi/ce/");
isa_ok($test_obj,'gen_project_config');
can_ok($test_obj,qw(get_flows_info));
#is($test_obj->get_flows_info(),'IHC:perl:ce_steerer:hdl_file_list:common:ce_tools','check all flows');

