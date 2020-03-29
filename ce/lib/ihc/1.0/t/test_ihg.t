#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;
use Data::Dumper;
use FileHandle;

BEGIN{use_ok('ihg')}

can_ok('ihg','new');
@ARGV = ('-top_file_list','t/test_input/project/cad/top.file_list.pl');
my $ihg = ihg->new();
$ihg->init();

can_ok($ihg,qw(get_file_list));
$ihg->get_file_list();
#is($ihg->{'file_list_info'}->{'filelist'}->{'dir1/dir2/dir3/module.v'}->{'ihg'},'dir1/ihg/dir3/module.ihg');
$ihg->parse_files();
my @res = $ihg->get_top_modules();
is(join('',@res),'top');
my $low_level = $ihg->get_tree_levels('top',\@res);
is($ihg->{'tree_level_max'}->{'top'},3);
my @top_array = qw(top);
my $expected_tree_level = { 'top' => { '1' => { 'top' => [ 'block_a', 'block_c', 'module1', 'block_b' ] },
                                       '3' => { 'block_d' => [ 'module1', 'module2' ] },
                                       '2' => { 'block_a' => [ 'block_d', 'module1' ],
                                                'block_c' => [ 'module1', 'module2' ],
                                                'block_b' => [ 'module1', 'module2' ] } } };

is(Dumper($ihg->{'tree_level'}),Dumper($expected_tree_level));
$ihg->check_tops(\@top_array);
$ihg->check_tops(undef);
# build verilog
$ihg->build_top_ihg_files('top');

 

