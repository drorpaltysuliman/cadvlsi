#!/usr/bin/perl -w
use file_list_functions;
add_ext(".v");
add_file("dir1/dir2/dir3/module.v");
add_files("cad_vlsi/project/uart/dut");
add_vfile("dir1/dir2/dir3/vmodule.v");
add_ydir("dir1/dir2/ydir4");
add_file("dir1/dir2/dir3/module1.v");
add_vfile("dir1/dir2/dir3/vmodule1.v");
include("cad_vlsi/ce/lib/hdl_file_list/test/input_files/top.file_list2.pl");

1;
