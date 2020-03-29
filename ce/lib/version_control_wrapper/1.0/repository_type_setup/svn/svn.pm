#!/usr/bin/env perl

use strict;
use warnings;

our $vc_cmd = { 'setup_cmd' => {'cmd' => 'svnadmin create $REPO_DIR',
                                'description' => 'Setup new repository to submit'},
                'vc_setup'  => {'type'=> 'file'},
                'submit'    => {'cmd' => 'ci',
                                'description' => 'Submit the files'},
                'sync'      => {'cmd' => 'co' ,
                                'description' => 'Check out the files'},
                'help'      => {'cmd' => 'help',
                                'description' => 'Command help'}};
                        

1;
