#!/usr/bin/perl -w
use file_list_functions;
find_replace("ihg","src");
find_replace("\.ihg","\.v");
add_ext(".v");
add_ext(".ihg");
add_file("t/test_input/project/src/module1.v");
add_file("t/test_input/project/src/module2.v");
add_file("t/test_input/project/ihg/top.ihg");
add_file("t/test_input/project/ihg/block_a.ihg");
add_file("t/test_input/project/ihg/block_b.ihg");
add_file("t/test_input/project/ihg/block_d.ihg");
add_file("t/test_input/project/ihg/block_c.ihg");
#include("/home/cad_vlsi/cad_vlsi/ce/lib/hdl_file_list/test/input_files/top.file_list2.pl");

1;
