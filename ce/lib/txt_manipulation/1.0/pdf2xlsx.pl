#!/usr/bin/perl 

use strict;
use warnings;

package pdf2xlsx;
use arguments_parser;
use CAM::PDF;
use CAM::PDF::PageText;
use Data::Dumper;

__PACKAGE__->main() unless caller; # executes at run-time, unless used as module

sub new{
    my $class = shift;
    my $self = {'pdf' => shift}; 
    bless $self, $class;
    return $self;
}

sub read_pdf{
    my ($self,$pdf_file)=@_;
    my $pdf = CAM::PDF->new("$pdf_file");
    my $page_tree = $pdf->getPageContentTree(1);
    $page_tree->render("CAM::PDF::Renderer::Text");
    my $text = CAM::PDF::PageText->render($page_tree);
    print $page_tree->toString();

    #print $text;
}

sub init{
    my $arg_handler = arguments_parser->new();
    $arg_handler->add_arg('-pdf','PDF fiel to convert',{'default' => undef});
    $arg_handler->process(@ARGV);
    return $arg_handler;
}


sub main{
    my $arg_handler = init();
    my $pdf_file = $arg_handler->{'arguments'}->{'-pdf'}->{'val'};
    my $pdf2xlsx = pdf2xlsx->new();
    $pdf2xlsx->read_pdf("$pdf_file");
}


1;
