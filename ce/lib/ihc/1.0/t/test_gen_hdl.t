#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
#use Test::Exception;
use Data::Dumper;
use FileHandle;
use ihg;
use gen_hdl;

can_ok('gen_hdl','new');
@ARGV = ('-top_file_list','t/test_input/project/cad/top.file_list.pl');
my $ihg = ihg->new();
$ihg->init();

can_ok($ihg,qw(get_file_list));
my $file_list_info = $ihg->get_file_list();
$ihg->parse_files();
$ihg->get_top_modules();
my $gh = gen_hdl->new($file_list_info,$ihg->{'modules_files'});
$gh->parse_files("top",$ihg->{'modules_files'});
#print STDERR Dumper($gh->{'parsed'});
$gh->build_module("block_b");
#throws_ok($gh->build_module("block_c"),1,"check exit when collision");

#print STDERR "KKK ".Dumper($file_list_info);
#reconstruct_file
#can_ok($ph,qw(add_instance_port 
#add_instance_param
#reconstruct_file
#add_port)); 

