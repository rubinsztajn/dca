#!/usr/bin/env ruby

#----------------------
# Tool for extracting text from a PDF and encoding it in some basic TEI
# This is a temporary script, kludging a basic text extraction for full text 
# searches of PDFs in the TDL. This script requires the docsplit gem, which itself
# has many requirements: http://documentcloud.github.com/docsplit/
#
# This is my first ever Ruby script so I apologize for the fact that it looks
# like hell.
#
# Usage:
# pdfextractor.rb [OBJID].archival.pdf
#
# Aaron Rubinstein 6/22/2011
#---------------------

require 'rubygems'
require 'docsplit'
require 'htmlentities'

# Initialize coder object for later sanitization
coder = HTMLEntities.new

# Grab PDF filename from input and create an outfile based on that name
filename = ARGV[0]
out_filename = File.basename(filename, ".archival.pdf") + ".access.xml"
out = File.new(out_filename, "w+")

# Extract text and read in resulting TXT file as a string
Docsplit.extract_text(filename)
text = File.read(File.basename(filename, ".pdf") + ".txt")

# Split text file at page breaks
pages = text.split("\f")

# TEI header section with PDF metadata

header = <<HEADER
<?xml version="1.0" encoding="utf-8" ?>
<TEI.2>
<teiHeader>
<fileDesc>
<titleStmt>
<title>#{Docsplit.extract_title(filename)}</title>
</titleStmt>
<publicationStmt>
<p>#{Docsplit.extract_producer(filename)}</p>
</publicationStmt>
<sourceDesc>
<p>Generated from a source PDF document</p>
</sourceDesc>
</fileDesc>
</teiHeader>
<text>
<body>
HEADER

out << header

# Loop through pages and insert them in TEI divs
i = 1
pages.each do |page|
  
  page_sanitized = coder.encode(page)

  div = <<DIV
<div1 id="page_#{i}" n="#{i}" type="page">
#{page_sanitized}
</div1>
DIV

  out << div
  i += 1
end

# End of the TEI doc
close = <<CLOSE
</body>
</text>
</TEI.2>
CLOSE

out << close
  
