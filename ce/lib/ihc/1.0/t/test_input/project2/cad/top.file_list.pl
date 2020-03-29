#!/usr/bin/perl -w
use file_list_functions;
find_replace("ihg","src");
find_replace("\.ihg","\.v");
add_ext(".v");
add_ext(".ihg");
add_file("t/test_input/project2/src/module1.v");
add_file("t/test_input/project2/src/module2.v");
add_file("t/test_input/project2/ihg/block_a.ihg");
add_file("t/test_input/project2/ihg/block_d.ihg");

1;
