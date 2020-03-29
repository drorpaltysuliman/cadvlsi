#!/usr/bin/env perl

use strict;
use warnings;

package gen_hdl;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);
use Data::Dumper;
use parse_hdl;
use hdl_file_list;
use common_package;


use constant SPACE => '{%sp%}';
use constant NEWLINE => '{%nl%}';

sub new{
    my $class = shift;
    my $self = {'file_list_info' => shift,'modules_files'=> shift, 'logger' => get_logger(),'file_info' => {}, 'module' => {},'current_module' => undef};
    #check if file exists 
    bless $self, $class;
    return $self;
}

sub add_instance_port{
    my ($self,$instance,$port)=@_;
}

sub add_instance_param{
}

sub check_number{
    my ($string)=@_;
    return ($string=~/^\d+$/) ? 1 : 0;
}

sub check_bit_collison{
    my ($self,$msb_ptr, $lsb_ptr)=@_;
    # confirm sizes of array are the same
    if ($#$msb_ptr ne $#$lsb_ptr){
        $self->{'logger'}->error("Internal error, sizes of msb/lsb arrays are not the same!!!");
        exit(1);
    }
    if (not $#$msb_ptr and not $#$lsb_ptr){
        return -1,"";
    }
    my %num_of_hash;
    for (my $i=0 ; $i<=$#$msb_ptr ; $i+=1){
        my $msb = $msb_ptr->[$i];
        my $lsb = $lsb_ptr->[$i];
        my $start = check_number($lsb) ? $lsb : check_number($msb) ? $msb : 0;
        my $end = check_number($msb) ? $msb : check_number($lsb) ? $lsb : 0;
        my @collide_bits = qw();
        #check if number and put in hash
        for (my $j=$start ; $j <=$end ; $j+=1){
            if (exists $num_of_hash{$j}){
                $self->{'logger'}->error("Collison found with bit $j!!!");
                return 1,"with bits $end:$start";
            }
            $num_of_hash{$j} = 1;
        }
    }
    return 0,"";

}

sub check_output_collison{
    my ($self,$top,$connect)=@_;
    my @direction_array = @{$self->{'toconnect'}->{$top}->{'if'}->{$connect}->{'direction'}};
    my @instance_array = @{$self->{'toconnect'}->{$top}->{'if'}->{$connect}->{'instance'}};
    my $msb_ptr = $self->{'toconnect'}->{$top}->{'if'}->{$connect}->{'msb'};
    my $lsb_ptr = $self->{'toconnect'}->{$top}->{'if'}->{$connect}->{'lsb'};
    #print Dumper($msb_ptr);
    #print Dumper($lsb_ptr);
    #check the direction to see there is no collison between outputs
    if (grep(/(output|inout)/,@direction_array) > 1){
        my ($status, $string) = $self->check_bit_collison($msb_ptr,$lsb_ptr);
        if ($status != 0){
            $self->{'logger'}->error("Instances in module $top have too many output ports with the same name $connect $string!!!");
            for (my $i=0;$i<=$#direction_array;$i++){
                if ($direction_array[$i] eq "output"){
                    $self->{'logger'}->error("    ".$instance_array[$i]);
                }
            }
        }
        #exit(1);
    }
}

sub check_direction{
    my ($self,$top,$connect)=@_;
    my @direction_array = common_package::uniqulify_array(@{$self->{'toconnect'}->{$top}->{'if'}->{$connect}->{'direction'}});
    #check the direction to see there is no collison between outputs
    #print STDERR "*" x 10 ."$top--$connect\n@direction_array\n";
    if (grep(/(output|input|inout)/,@direction_array) > 1){
        return 'wire'
    } elsif ($#direction_array == 0){
        return $direction_array[0];
    } else {
        $self->{'logger'}->error("could not figure out direction of $connect in module $top!!!");
        exit(1);        
    }

}


sub add_wires_ports{
    my ($self,$top)=@_;
    foreach my $connect (keys %{$self->{'toconnect'}->{$top}->{'if'}}){
        #check if there are more than one output
        $self->check_output_collison($top,$connect);
        my $type = $self->check_direction($top,$connect);
        $self->{'connected'}->{$top}->{$type}->{$connect} = $self->{'toconnect'}->{$top}->{'if'}->{$connect};
    }
}

sub sort{
    my ($a,$b)=@_;
    # think how to sort according to direction as well.
}


sub get_missing_ports{
    my ($module_ports_ptr,$inst_ports_ptr)=@_;
    my @missing_ports = ();
}

# this function should get the max number exists in a variable in the replace
sub get_max_var_num{
    my ($self,$string)=@_;
    my $max = 0;
    while($string=~s/\$(\d+)//){
        $max = ($1 > $max) ? $1 : $max;
    }
    return $max;
}

sub get_regex_new_value{
    my ($self,$top,$instance,$regex_hash,$inst_module,$string)=@_;
    foreach my $find (keys %$regex_hash){
        my $replace = $regex_hash->{$find};
        my $max_var_num = $self->get_max_var_num($replace);
        if ($string=~s/$find/$replace/ and $max_var_num){
            # save all variables values
            my @regex_mem;
            no strict;
    	    for(my $i=1;$i<=$max_var_num;$i++){
    		    push(@regex_mem,${"$i"});				
    		}
            for (my $i=1 ; $i <= $max_var_num ; $i++){
                my $match = $regex_mem[$i-1];
                $string=~s/\$$i/$match/g;
            }
        }
    }
    return $string;
}

sub get_instance_regex_match{
    my ($self,$top,$instance,$module)=@_;
    my @regex_mem;
    if (defined $self->{'parsed'}->{$top}->{'AUTO_TEMPLATE'}){
        foreach my $iregex (keys %{$self->{'parsed'}->{$top}->{'AUTO_TEMPLATE'}}){
            no strict;
            if ($instance=~/$iregex/){
                my $i = 1;
                while(defined ${"$i"}){
    	    	    push(@regex_mem,${"$i"});
                    $i += 1;				
    	    	}
                return $self->{'parsed'}->{$top}->{'AUTO_TEMPLATE'}->{$iregex}->{'io'}, \@regex_mem;
            } elsif ($module=~/$iregex/){
                my $i = 1;
                while(defined ${"$i"}){
    	    	    push(@regex_mem,${"$i"});
                    $i += 1;				
    	    	}
                return $self->{'parsed'}->{$top}->{'AUTO_TEMPLATE'}->{$iregex}->{'io'}, \@regex_mem;
            }
        }
    }
    return undef, undef;
}


sub get_instance_auto_template_info{
    my ($self,$top,$instance,$module)=@_;
    # checking if instance meet regex
    if (defined $self->{'parsed'}->{$top}->{'AUTO_TEMPLATE'}->{$instance}->{'io'}){
        return $self->{'parsed'}->{$top}->{'AUTO_TEMPLATE'}->{$instance}->{'io'};
    } elsif (defined $self->{'parsed'}->{$top}->{'AUTO_TEMPLATE'}->{$module}->{'io'}) {
        return $self->{'parsed'}->{$top}->{'AUTO_TEMPLATE'}->{$instance}->{'io'};
    } else {
        return undef
    }    
}

sub execute_inst_regex{
    my ($self, $string, $regex_ptr)=@_;
    no strict;
    for(my $i = 0 ; $i<=$#$regex_ptr ; $i+=1){
        my $replace = $regex_ptr->[$i];     
        my $find = "\\\$i".($i+1);
        $string=~s/$find/$replace/g;
    }
    return $string;
}

sub add_instances_ports{
    my ($self,$top)=@_;
    my $connect_info = $self->{'toconnect'}->{$top};
    foreach my $instance (keys %{$self->{'parsed'}->{$top}->{'instance'}}){
        my $inst_info = $self->{'parsed'}->{$top}->{'instance'}->{$instance};
        my $inst_module = $inst_info->{'module'};
        my $module_info = $self->{'parsed'}->{$inst_module};
        my ($regex_hash, $iregex_ptr) = $self->get_instance_regex_match($top,$instance,$inst_module);
        #getting missing ports
        foreach my $port (sort(keys %{$module_info->{'io'}})){
            my $port_regex = $self->get_regex_new_value($top,$instance,$regex_hash,$inst_module,$port);
            # replacing regex of instance
            my $connected_wire = $self->execute_inst_regex($port_regex,$iregex_ptr);
            # getting the actual wire/port name
            my ($port_wire, $msb, $lsb) = $self->get_wire_info($connected_wire);
            $connect_info->{'instance'}->{$instance}->{'io'}->{$port} = $connected_wire;
            # adding information for the top level
            push(@{$self->{'toconnect'}->{$top}->{'if'}->{$port_wire}->{'instance'}},$instance);
            # need to write params to the new block
            foreach my $mparam (keys %{$module_info->{'param'}}){
                push(@{$self->{'toconnect'}->{$top}->{'param'}->{$mparam}},$module_info->{'param'}->{$mparam});
            }
            foreach my $info_key (keys %{$module_info->{'io'}->{$port}}){
                my $info_val = $module_info->{'io'}->{$port}->{$info_key};
                # flipping lsb/msb according to connectded wire
                $info_val = ($info_key eq "msb" and defined $msb) ? $msb : $info_val;
                $info_val = ($info_key eq "lsb" and defined $lsb) ? $lsb : $info_val;
                push(@{$self->{'toconnect'}->{$top}->{'if'}->{$port_wire}->{$info_key}},$info_val);
                #print "$port ".Dumper($module_info->{'io'}->{$port});
            }
            # now need to add ports after figuring out the missing ones.
        }
    }
}

sub add_params{
    my ($self,$top)=@_;
    foreach my $type (keys %{$self->{'connected'}->{$top}}){
        foreach my $port (keys %{$self->{'connected'}->{$top}->{$type}}){
            foreach my $mb ( qw(lsb msb) ){
                my $mb_val = $self->{'connected'}->{$top}->{$type}->{$port}->{$mb};
                if (defined $mb_val){
                    foreach my $param (keys %{$self->{'toconnect'}->{$top}->{'param'}}){
                        if (grep(/\b$param\b/,@$mb_val)){
                            my @param_res = @{$self->{'toconnect'}->{$top}->{'param'}->{$param}};
                            if ($#param_res > 0){
                                $self->{'logger'}->info("Param $param has several values, taking first");
                            }
                            $self->{'connected'}->{$top}->{'param'}->{$param} = $param_res[0];
                        }
                    }
                }
            }
        }
    }
}


sub get_wire_info{
    my ($self,$connection)=@_; 
    my $parse_obj = parse_hdl->new();
    my ($msb,$lsb) = $parse_obj->get_msb_lsb(\$connection, 1);
    return $connection,$msb,$lsb;
}

sub get_file_to_parse{
    my ($self,$internal_module,$children)=@_;
    if (not exists $self->{'modules_files'}->{$internal_module}){
        $self->{'logger'}->error("Did not find file for module $internal_module");
        exit(1);
    } 
    my $module_file = $self->{'modules_files'}->{$internal_module};
    if (not -e $module_file){
        $self->{'logger'}->error("File $module_file for module $internal_module does not exists");
        return undef;    
    }
    if (defined $self->{'file_list_info'}->{'filelist'}){
        if (exists $self->{'file_list_info'}->{'filelist'}->{$module_file}){
            my $fr_file_name = $self->{'file_list_info'}->{'filelist'}->{$module_file}->{'fr'};
            my $final_file = (defined $fr_file_name and -e $fr_file_name and $children) ? $fr_file_name : $module_file;
            if (not -e $final_file){
                $self->{'logger'}->error("File $final_file does not exists!!!");
                exit(1);
            } else {
                return $final_file;
            }
        }
    }
}


sub get_module_info{
    my ($self,$top,$children)=@_;
    my $file_to_parse = $self->get_file_to_parse($top,$children);
    my $parse_file = parse_hdl->new();
    $parse_file->read_file($file_to_parse);
    return $parse_file->{'module'}->{$top}
}

sub parse_children{
    my ($self,$top,$top_internal_modules_ptr) = @_;
    foreach my $internal_module (@{$top_internal_modules_ptr}){
        $self->{'parsed'}->{$internal_module} = $self->get_module_info($internal_module,1);
    }
}

sub get_sb{
    my ($sb,$msb_flag)=@_;
    my $val_to_return;
    if (ref($sb) eq "ARRAY"){
        # check if all numbers are integers
        foreach my $val (@{$sb}){
            my $relevant_flag = (!defined $val_to_return or ($val=~/^\d+$/ and $val_to_return=~/^\d+$/)) ? 1 : 0; 
            my $big_val = (!defined $val_to_return or ($relevant_flag and $val_to_return < $val)) ? $val : $val_to_return;
            my $small_val = (!defined $val_to_return or ($relevant_flag and $val_to_return > $val)) ? $val : $val_to_return;
            $val_to_return = ($msb_flag) ? $big_val : $small_val; 
        }
    }
    return $val_to_return;
}

sub get_msb_lsb_str{
    my ($self,$msb_ptr,$lsb_ptr)=@_;
    my $msb = get_sb($msb_ptr,1);
    my $lsb = get_sb($lsb_ptr,0);
    if ($msb eq '0' and $lsb eq '0'){
        return "";
    } else {
        return "[$msb:$lsb]";
    }
}

# add to the raw string the wires/ports
sub dump_connection_to_file_str{
    my ($self, $top, $filename)=@_;
    my $parse_obj = parse_hdl->new();
    my ($newline,$space) = $parse_obj->get_special_var();
    my $veri2001 =  $self->{'parsed'}->{$top}->{'veri2001'};
    # put all inputs
    foreach my $type ("input","output","inout","wire"){
        my $ptr = $self->{'connected'}->{$top}->{$type};
        foreach my $if (keys %{$ptr}){
            my $msb_lsb_str = $self->get_msb_lsb_str($ptr->{$if}->{'msb'},$ptr->{$if}->{'lsb'});
            my $suffix = ($veri2001 and $type ne "wire") ? "," : ";";
            if (not $self->{'parsed'}->{$top}->{'filestr'}=~s/(\/\*($space|)*auto($space|)*$type($space|)*\*\/)/$1\n$type $msb_lsb_str $if $suffix/){
                $self->{'logger'}->error("Could not find string \/\*auto$type\*\/ in file $filename");
                $self->{'logger'}->error("Please add one to file!!!");
                exit(1);
            }          
        }
    }
}


#cleanup all bad syntax from string
sub cleanup_str{
    my ($self,$top)=@_;
    my $parse_obj = parse_hdl->new();
    my ($newline,$space) = $parse_obj->get_special_var();
    $self->{'parsed'}->{$top}->{'filestr'}=~s/\,($newline|$space)*\)/)/g;
}

#add insatnce ports

sub dump_instance_port_to_file_str{
    my ($self, $top, $filename)=@_;
    my $parse_obj = parse_hdl->new();
    my ($newline,$space) = $parse_obj->get_special_var();
    my $veri2001 =  $self->{'parsed'}->{$top}->{'veri2001'};
    # put all inputs
    foreach my $instance (keys %{$self->{'toconnect'}->{$top}->{'instance'}}){
        my $inst_io_ptr = $self->{'toconnect'}->{$top}->{'instance'}->{$instance}->{'io'};
        my $module = $self->{'parsed'}->{$top}->{'instance'}->{$instance}->{'module'};
        foreach my $port (keys %$inst_io_ptr){
            my $wire = $inst_io_ptr->{$port};
            if (not $self->{'parsed'}->{$top}->{'filestr'}=~s/(\b$module\b(\S+?)\b$instance\b($space|$newline)*\()/$1\n\.$port($wire),/){
                $self->{'logger'}->error("Could not find instance $instance in file $filename");
                exit(1);                
            }
        }
    }
    $self->cleanup_str($top);
}

#add insatnce params

sub dump_instance_param_to_file_str{
    my ($self, $top, $filename)=@_;
    my $parse_obj = parse_hdl->new();
    my ($newline,$space) = $parse_obj->get_special_var();
    my $veri2001 =  $self->{'parsed'}->{$top}->{'veri2001'};
    # put all inputs
    foreach my $param (keys %{$self->{'connected'}->{$top}->{'param'}}){
        my $value = $self->{'connected'}->{$top}->{'param'}->{$param}->{'val'};
        my $param_str = "$param=$value";
        my $file_str = $self->{'parsed'}->{$top}->{'filestr'};
        if (not $self->{'parsed'}->{$top}->{'filestr'}=~s/(^($space|$newline)*\#($space|$newline)*\()/$1parameter$space$param_str,$newline/ and not $self->{'parsed'}->{$top}->{'filestr'}=~s/^/#(parameter$space$param_str,$newline)/){
            $self->{'logger'}->error("Could not find module $top");
            exit(1);                
        }
    }
    $self->cleanup_str($top);
}

# add to the raw string the wires/ports
sub reconstruct_module{
    my ($self, $top, $filename)=@_;
    my $filestr = $self->{'parsed'}->{$top}->{'filestr'};
    my $parse_obj = parse_hdl->new();
    my ($newline,$space) = $parse_obj->get_special_var();
    $filestr=~s/$newline/\n/g;
    $filestr=~s/$space/ /g;
    $self->{'logger'}->info("Writing file $filename\n");
    open FILE ,">$filename" or die "cannot open file $filename : $!\n";
    print FILE "module $top $filestr";
    close (FILE);
}


#--------------------------------------------------------------------------------------
# parsing only the top specified, the assumption is that we build 
# one module for each file
# need to consider cases that we use two modules in the same file and 
# overwriting the generated file
#--------------------------------------------------------------------------------------
sub parse_files{
    my ($self,$top)=@_;
    $self->{'parsed'}->{$top} = $self->get_module_info($top,0);
    my @top_internal_modules = keys %{$self->{'parsed'}->{$top}->{'modules'}};
    $self->parse_children($top,\@top_internal_modules);     
    return;
}


sub get_module_out_file{
    my ($self,$top)=@_;
    my $module_file = $self->{'modules_files'}->{$top};
    if (defined $self->{'file_list_info'}->{'filelist'}->{$module_file}->{'fr'}){
        return $self->{'file_list_info'}->{'filelist'}->{$module_file}->{'fr'};
    } else {
        return undef;
    }
}

sub build_module{
    my ($self,$top)=@_;
    my $file_out = $self->get_module_out_file($top);
    $self->parse_files($top);
    $self->{'toconnect'}->{$top} = {};
    $self->add_instances_ports($top);
    $self->add_wires_ports($top);
    $self->add_params($top);
    # copy the file string to add new things to it.
    $self->{'filestr'}->{$top} = $self->{'parsed'}->{$top}->{'filestr'};
    $self->dump_connection_to_file_str($top, $self->get_file_to_parse($top));
    $self->dump_instance_port_to_file_str($top, $self->get_file_to_parse($top));
    $self->dump_instance_param_to_file_str($top, $self->get_file_to_parse($top));
    $self->reconstruct_module($top, $file_out);
}


