#!/usr/bin/env perl

#----------------------
# Tool for extracting text from a PDF and encoding it in some basic TEI
# This is a temporary script, kludging a basic text extraction for full text 
# searches of PDFs in the TDL.
#
# pdfextractor.pl [OBJID].archival.pdf
#
# Aaron Rubinstein 4/13/2011
#---------------------

use strict;
use warnings;
use XML::Code;
use CAM::PDF;
use Encode;

# Grab input filename from STDIN, parse out OBJID, and create output filename
my $input_file = shift @ARGV;
$input_file =~ /(.*)archival.pdf$/;
my $out_name = $1 . 'access.xml';

open(my $out, '>', $out_name) or die $!;

# Create PDF object
my $pdf = CAM::PDF->new($input_file) or die "$CAM::PDF::errstr\n";

# Print TEI header to output file
print $out <<HEADER;
<?xml version="1.0" encoding="utf-8" ?>
<TEI.2>
<teiHeader>
<fileDesc>
<titleStmt>
<title>No title</title>
</titleStmt>
<publicationStmt>
<p>No publication information is available</p>
</publicationStmt>
<sourceDesc>
<p>Generated from a source PDF document</p>
</sourceDesc>
</fileDesc>
</teiHeader>
<text>
<body>
HEADER

# Loop through each pdf page and generate TEI divs
for (my $i = 1; $i < $pdf->numPages(); $i++) {

    my $page_text = $pdf->getPageText($i);

    # Decode extracted text into utf-8 and exclude invalid characters
    my $unicode_string = decode("utf-8", $page_text);

    # Create a new <p> for each page and convert illegal XML text to entities
    my $p = new XML::Code ('p');
    $p->set_text($unicode_string);
    $p->escape(1);
    my $escaped_page_text = $p->code();

    # Print page <div> and include <p> of extracted and sanitized text to output
    print $out <<TEXT;
<div1 id="page_$i" n="$i" type="page">
$escaped_page_text
</div1>
TEXT

}

# Close TEI document and print to output
print $out <<CLOSE;
</body>
</text>
</TEI.2>
CLOSE


