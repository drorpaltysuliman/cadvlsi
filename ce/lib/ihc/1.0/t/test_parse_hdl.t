#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 12;
use Data::Dumper;
use FileHandle;

BEGIN{use_ok('parse_hdl')}

can_ok('parse_hdl','new');
my $ph = parse_hdl->new("t/test_input/top.v");
can_ok($ph,qw(read_file 
check_line 
check_endmodule
get_module_instances
get_name_and_type 
remove_special_marks 
remove_spaces
remove_functions
remove_tasks
remove_sv_clocking
read_file
check_def_line
get_module_name));
my $flat_str = $ph->flat_file('t/test_input/flat_check.txt');
my ($newline,$space) = parse_hdl::get_special_var();
is($flat_str,"bla${space}bla${space}${newline}hhh${space}${space}kkk${newline}oo${space}${newline}", "Check flat file function");
my $comment_str = "bla${space}bla/*${space}${newline}hh*/h//${space}${space}kkk${newline}oo${space}${newline}";
my $uncomment_str = "bla${space}blahoo${space}${newline}";
my $comments = "${space}${newline}hh${newline}${space}${space}kkk${newline}";
is(join(':::',$ph->seperate_comments($comment_str)),"${uncomment_str}:::$comments");
my $instance_str = '{%sp%}AUTO_TEMPLATE{%sp%}check2({%nl%}{%nl%}.bla\\(\w+\\)(bla_$1),{%nl%}.kjlds(uuduu));';
$ph->{'current_module'} = 'nomod';
$ph->get_auto_info($instance_str);
my $instance_with_auto_template = {'check2' => {'params' => {},
                                                'io' => {'kjlds' => 'uuduu','bla(\w+)' => 'bla_$1'},
                                                'module' => 'AUTO_TEMPLATE'}};
is(Dumper($ph->{'module'}->{'nomod'}->{'AUTO_TEMPLATE'}),Dumper($instance_with_auto_template));
my $io = {  'txclk'         => {'direction' => 'input','msb' => '0','lsb' => '0','val'=>undef},
            'ld_tx_data'    => {'direction' => 'input','msb' => '0','lsb' => '0','val'=>undef},
            'reset'         => {'direction' => 'input','msb' => '0','lsb' => '0','val'=>undef},
            'tx_data'       => {'direction' => 'input','msb' => '7','lsb' => '0','val'=>undef},
            'tx_enable'     => {'direction' => 'input','msb' => '0','lsb' => '0','val'=>undef}};
# checking variety of input/output 
foreach my $file (`find t/test_input/syntax_variant/*.v`){
    chomp($file);
    my $ph = parse_hdl->new();
    my $flat_module_str = $ph->read_file($file);
    is(Dumper($ph->{'module'}->{'uart'}->{'io'}),Dumper($io));
}
my $flat_str_inst = $ph->flat_file('t/test_input/instances/uart.v');
$ph->get_module_info($flat_str_inst);
my $instances = {   'check2' => {'params' => {},'io' => { 'input1' => 'wire1',
                                                             'input2' => 'wire2',   
                                                             'input3' => 'wire3',   
                                                             'input4' => 'wire4'},
                                 'module' => 'check1'},
                    'check4' => {'params' => {  'param2' => 'mmsms[rr+11pp]',
                                                'param1' => 'uuud'},
                                 'io' => { 'input1' => 'wire1[5:4]',
                                              'input2' => 'wire2[PARAM2-1:0]',
                                              'input3' => 'wire3',
                                              'input4' => 'wire4'}, 
                                 'module' => 'inst2c'}};

is(Dumper($ph->{'module'}->{'uart'}->{'instance'}),Dumper($instances));
# test parameters
my $ph2 = parse_hdl->new();
$ph2->read_file("t/test_input/project/ihg/block_b.ihg");


#print STDERR "LLLLL ".Dumper($ph->{'module'});
#is(join(":",$fl->get_blocks()),'ggg/hhh/lll.pl','check column line information');
#$hfl->file_list_handle();
#my @ARGV_DUMMY = ('-head','ggg/hhh/lll.pl','-array','lll','jjj','-bol');
#isa_ok($ap,'arguments_parser');

 

