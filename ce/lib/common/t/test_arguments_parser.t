#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;
use Data::Dumper;

BEGIN{use_ok('arguments_parser')}

can_ok('arguments_parser','new');
my $ap = arguments_parser->new();
my @ARGV_DUMMY = ('-head','ggg/hhh/lll.pl','-array','lll kkkd','jjj','-bol');
isa_ok($ap,'arguments_parser');
can_ok($ap,qw(add_arg get_arg process help));
$ap->add_arg('-head','Location of the head file to read',{'default' => undef});
$ap->add_arg('-array','Location of the head file to read',{'default' => undef,'type'=>"array"});
$ap->add_arg('-bol','Location of the head file to read',{'default' => '1','type'=>"bool"});
$ap->add_arg('-bool','Location of the head file to read',{'default' => '0','type'=>"bool"});
$ap->process(@ARGV_DUMMY);
is($ap->get_arg('-head'),'ggg/hhh/lll.pl','check head val');
is(join(":",@{$ap->get_arg('-array')}),'lll kkkd:jjj','check array val');
is($ap->get_arg('-bol'),'0','check boolean default true val');
is($ap->get_arg('-bool'),'0','check boolean val');

