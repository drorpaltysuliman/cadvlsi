#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;
use Data::Dumper;
use File::Basename;

BEGIN{use_ok('hdl_file_list')}

can_ok('hdl_file_list','new');
my $hfl = hdl_file_list->new(dirname(__FILE__)."/input_files/top.file_list.pl");
@ARGV = ('-head','ggg/hhh/lll.pl','-var','stam1=rrr','stam2=eee','ol','-bol');
$hfl->init();
can_ok($hfl,qw(split_var set_vars));
is(join(":",$hfl->split_var("stam=kkk")),'stam:kkk','check variable with key');
is(join(":",$hfl->split_var("stam")),'stam:1','check variable with key');
#is(join(":",$hfl->split_var("stam?")),1,'check variable with key');
$hfl->set_vars();
is($ENV{'stam1'},"rrr",'check variable with key');
is($ENV{'ol'},1,'check variable with key');

