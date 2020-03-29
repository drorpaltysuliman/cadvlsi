#!/usr/bin/env perl

use strict;
use warnings;

package parse_hdl;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);
use Data::Dumper;

use constant SPACE => '{%sp%}';
use constant NEWLINE => '{%nl%}';

sub new{
    my $class = shift;
    my $self = {'logger' => get_logger(),'file_info' => {}, 'module' => {},'current_module' => undef};
    #check if file exists 
    bless $self, $class;
    return $self;
}

sub check_line{
	my ($line)=@_;
	if ($line=~/^\s*$/){
		return 1;
		}
	elsif ($line=~/^\s*\/\//){
		return 1;
		}
	elsif ($line=~/^\s*--/){
		return 1;
		}
	return 0;
	}

sub get_preserved_words{
    my @words = qw(begin end if);
    return @words;
}

sub check_endmodule{
	my ($line)=@_;
        if ($line=~/^\s*endmodule/){
		return 1;
		}
	return 0;
	}

sub get_name_and_type{
	my ($line)=@_;
	if ($line=~/^\s*(module|program|interface)\s+(\w+)/){
		return ($1, $2);
		}
	return ("" , "");
	}

sub remove_special_marks{
	my ($string)=@_;
	$string=~s/=$//;
	return $string;
	}

sub remove_spaces{
	my ($self, $string)=@_;
    my ($newline,$space) = $self->get_special_var();
	$string=~s/($newline|$space)//g;
	return $string;
	}
	
sub remove_functions{
	my ($line)=@_;
	if ($line=~/\bfunction\b/){
		while ($line=<FILE>){
			if ($line=~/\bendfunction\b/){last;}
			}
		}
	return $line;
	}
sub remove_tasks{
	my ($line)=@_;
	if ($line=~/\btask\b/){
		while ($line=<FILE>){
			if ($line=~/\bendtask\b/){last;}
			}
		}
	return $line;
	}
	
sub remove_sv_clocking{
	my ($line)=@_;
	if ($line=~/^\s*\bclocking\b/){
		while ($line=<FILE>){
			if ($line=~/\bendclocking\b/){last;}
			}
		}
	return $line;
	}

sub check_def_line{
	my ($line,$current)=@_;
	if ($line=~/`(ifdef|elsif)\s+(\w+)/){
		return $1;
		}
	elsif ($line=~/`(ifdef|elsif)\s+(\w+)/){
		return $1;
		}
	elsif ($line=~/`else/){
        return "ELSE"
		}
	elsif ($line=~/`endif/){
		return undef;
		}
    return $current;
	}

sub check_parameter_line{
	my ($line,$current)=@_;
	if ($line=~s/\bparameter\b//gi){
		return 1;
		}
	if ($line=~/\);/){
		return 0;
		}
    return $current;
	}

sub flat_file{
    my ($self,$file)=@_;
	open FILE ,$file or die "cannot open file $file : $!\n";
    # put the file in an array
    chomp(my @lines = <FILE>);
    close(FILE);
    my $str = join(NEWLINE,@lines);
    my $space = SPACE;
    $str=~s/\s/$space/g;
    return $str;
}

sub reconstruct_file{
    my ($str)=@_;
    $str=~s/SPACE/ /;
    my @lines = split($str,NEWLINE);
    return @lines;
}

sub clean_space_newline{
    my ($self, $string) = @_;
    return if not defined $string;
    my ($newline,$space) = $self->get_special_var();
    $string=~s/$newline//g;
    $string=~s/$space//g;
    return $string;
}


sub get_module_io{
    my ($self,$str)=@_;
    my ($newline,$space) = $self->get_special_var();
    my $module = $self->{'current_module'};
    $$str=~/\((\S+?)\)/;
    my $in_out_str = $1;
    my $str_2_find = '(\binput\b|\boutput\b|\binout\b|\bparameter\b)';
    my $veri2001_flag = ($in_out_str=~/$str_2_find/ 
                          or $in_out_str=~/^($newline|$space)*$/) ? 1 : 0;
    my $reg2look = ($veri2001_flag) ? ",($newline|$space)*$str_2_find" : ";";  
    $self->{'module'}->{$module}->{'veri2001'} = $veri2001_flag;
    while($$str=~s/(.*?)(\binput\b|\boutput\b|\binout\b|\bparameter\b)(\S+?)(($reg2look)|\))/$4/){
        my $direction = $2;
        my $inout_str = $3;
        # checking if there are msb/lsb information
        my ($msb,$lsb) = $self->get_msb_lsb(\$inout_str);
        my $type = $self->get_io_type(\$inout_str);
        my @port = $self->get_ports($inout_str);
		for (my $i=0;$i<=$#port;$i++){
            my $type = ($direction eq "parameter") ? 'param' : 'io';
            my ($param,$value) = ($type eq 'io') ? (undef,undef) : split("=",$port[$i]);
            my $port_param = ($type eq 'io') ? $port[$i] : $param;
            if ($port_param eq ''){
                $self->{'logger'}->error("Found an empty port/param, please check your syntax in module $module \n");
            next;                
            }
            $self->{'module'}->{$module}->{$type}->{$port_param} = {'msb' => $msb, 'lsb' => $lsb , 'direction' => $direction,'val' => $value};
		}
    }
}


sub convert_str_mem_brackets_to_special_str{
    my ($string,$reverse)=@_;
    my %flip = ($reverse) ? ( "KJKJENDREGMEM" => "\(" , "KJKJSTARTREGMEM" => "\)") : ( "\\\\\\(" => "KJKJENDREGMEM" , "\\\\\\)" => "KJKJSTARTREGMEM");
    foreach my $key (keys %flip){
        my $value = $flip{$key};
        $string=~s/$key/$value/g;
    }
    return $string;
}


sub get_instance_connectivity{
    my ($self,$str,$comment)=@_;
    my ($newline,$space) = $self->get_special_var();
    my %param_hash;
    if (defined $str and $str ne ""){
        $str = convert_str_mem_brackets_to_special_str($str,0) if $comment;
        while($str=~s/\.(\S+?)($newline|$space)*\((\S+?)\)($newline|$space)*(,|$)//){
            my $key = ($comment) ? convert_str_mem_brackets_to_special_str($1,1) : $1;
            my $value = ($comment) ? convert_str_mem_brackets_to_special_str($3,1) : $3;
            $param_hash{$key} = $self->remove_spaces($value);
        }
    }
    return \%param_hash;
}


sub get_module_instances{
    my ($self,$str)=@_;
    my ($newline,$space) = $self->get_special_var();
    my $top = $self->{'current_module'};
    while($str=~s/($newline|$space)*(\w+)($newline|$space)*(\#($newline|$space)*\((\S+?)\))*($newline|$space)*(\w+)($newline|$space)*\((\S*?)\)($newline|$space)*;//){
        my $module = $2;
        my $instance = $8;
        my $params = $6;
        my $ports = $10;
        next if (grep(/^$instance$/, get_preserved_words()));
        $self->{'module'}->{$top}->{'instance'}->{$instance} = { 'module' => $module , 'params' => $self->get_instance_connectivity($params,0) , 'io' => $self->get_instance_connectivity($ports,0) };
        $self->{'module'}->{$top}->{'modules'}->{$module} = 1;
	}
}

sub get_auto_info{
    my ($self,$str,$file)=@_;
    my ($newline,$space) = $self->get_special_var();
    my $top = $self->{'current_module'};
    my $new_str = convert_str_mem_brackets_to_special_str($str,0);
    my $auto_template_flag = ($new_str=~/AUTO_TEMPLATE/) ? 1 : 0;
    my $in_str_flag = 0;
    while($new_str=~s/($newline|$space)*(AUTO_TEMPLATE)($newline|$space)*(\#($newline|$space)*\((\S+?)\))*($newline|$space)*([\w\+\\]+?)($newline|$space)*\((\S*?)\)($newline|$space)*;//){
        # flag to specify an error if auto_template exists and not visited
        $in_str_flag = 1;
        my $module = $2;
        my $instance = $8;
        my $params = $6;
        my $ports = $10;
        next if (grep(/^$instance$/, get_preserved_words()));
        next if ($module ne 'AUTO_TEMPLATE');
        my $instance_new = convert_str_mem_brackets_to_special_str($instance,1);
        $self->{'module'}->{$top}->{'AUTO_TEMPLATE'}->{$instance_new} = { 'module' => $module , 'params' => $self->get_instance_connectivity($params,1) , 'io' => $self->get_instance_connectivity($ports,1) };
	}
    if ($auto_template_flag and not $in_str_flag){
        $self->{'logger'}->info("AUTO_TEMPLATE found but not processed in $file, please check your syntax");
    }
}


sub clean_spaces{
    my ($self, $str)=@_;
    my ($newline,$space) = $self->get_special_var();
    $str=~s/($newline|$space)//g;
    return $str;
}

sub get_ports{
    my ($self, $str)=@_;
    my @ports=split(',',$str);
    foreach my $port (@ports){
        # remove all the begining and end the str spaces
        $port = $self->clean_spaces($port);
    }
    return @ports;
    
}

sub get_msb_lsb{
    my ($self, $str, $return_undef)=@_;
    my ($newline,$space) = $self->get_special_var();
    if ($$str=~s/($space|$newline)*\[($space|$newline)*(\S+?)($space|$newline)*-?:($space|$newline)*(\S+?)($space|$newline)*\]//){
        return $self->clean_space_newline($3),$self->clean_space_newline($6);    
    } elsif ($$str=~s/($space|$newline)*\[($space|$newline)*(\S+)($space|$newline)*\]//){
        my $bit = $self->clean_space_newline($3);
        return $bit,$bit;    
    }
    if (defined $return_undef){
        return undef,undef
    }
    return '0','0';
}

sub get_io_type{
    my ($self, $str)=@_;
    my ($newline,$space) = $self->get_special_var();
    if ($$str=~s/(\breg\b|\bwire\b|\bbit\b)//){
        return $1;    
    }
    return undef;
}

sub get_special_var{
    my ($self)=@_;
    return NEWLINE,SPACE;
}

sub get_module_info{
    my ($self,$str,$file)=@_;
    my ($newline,$space) = $self->get_special_var();
    my $modulename = $self->get_module_name(\$str);
    if (defined $modulename){
        $self->{'module'}->{$modulename}->{'filestr'} = $str;
        my ($nocomment_str,$comments) = $self->seperate_comments($str);
        $self->get_module_io(\$nocomment_str);
        # get comments information if exists
        $self->get_module_instances($nocomment_str);
        $self->get_auto_info($comments,$file);
    } else {
        $self->{'logger'}->error("No module found in $file\n");
    }
}

sub read_file{
    my ($self,$file)= @_;
    if (not $file or not -e $file){
        my $string_to_print = ($file) ? "File $file does not exists" : "Uninitialized value for file";
        $self->{'logger'}->error("$string_to_print\n");
        return undef;
    }  
    my $module_name = undef;    
    my $param_flag = 0;
    my $def_flag;
    my @orig_lines = ();
    # get it in one big string to easily parse it.
    my $str = $self->flat_file($file);
    while($str=~s/(\bmodule\b.*\bendmodule\b?)//){
        $self->get_module_info($1,$file); 
    }
}

#-------------------------------------------------------------------------------
# This function returns all modules in the files
#-------------------------------------------------------------------------------

sub get_file_modules{
    my ($self,$top)=@_;
    return (keys %{$self->{'module'}});
}


#-------------------------------------------------------------------------------
# This function erase comments in a line 															
#-------------------------------------------------------------------------------

sub seperate_comments{
	my ($self,$str)=@_;
    my ($newline,$space) = $self->get_special_var();
    my $module = $self->{'current_module'};
    my $comment_num = 0;
    my $comment_str = "";
    while ($str=~s/\/\*(\S+?)\*\/|\/\/(\S+?$newline)|--(\S+?$newline)//){
        # added new line to $1 since there are case where 
        # autoinput/autooutput concatenated together in a wrong way
        my $comment = (defined $1) ? $1.$newline : (defined $2) ? $2 : $3;  
        $comment_str=$comment_str.$comment;
    }
	return $str,$comment_str;
	}	


sub fix_var{
	my ($var)=@_;
	chomp($var);
	my $CLOG2 = ($var=~s/(\$clog2\(.*\))/TEMPORARY_CLOG/) ? $1 : "";
	$var=~s/\s*;\s*$//;
	$var=~s/\s*,\s*$//;
	$var=~s/\s*\)\s*\(?\s*$//;
	$var=~s/TEMPORARY_CLOG/$CLOG2/;
	return $var;
	}



sub get_module_name{
	my ($self,$line)=@_;
    my ($newline,$space) = $self->get_special_var();
	if ($$line=~s/(\bmodule\b|\bprogram\b|\binterface\b)($newline|$space)+(\w+)//){
        $self->{'current_module'} = $3;
		return $3;
		}
    $self->{'current_module'} = undef;
    return undef;
	}


