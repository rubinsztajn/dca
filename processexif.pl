#!/usr/bin/env perl

# Used to extract EXIF metadata from the University Photographs
# and generate a CSV file of the resulting metadata
#
# File paths are hardcoded into script
#
# Aaron Rubinstein, Archivist for Digital Collections, 2011
use warnings;
use strict;
use Lingua::EN::Sentence qw( get_sentences );
use Image::ExifTool qw(:Public);
use Data::Dumper;
use Digest::MD5;
use File::Find;
use Text::CSV::Simple;

my $startdir = shift @ARGV;


# Create outgoing CSV file and print header
open(my $out, ">", "fileinfo.csv");
print $out '"filename","md5","title","description","creator","coll_nbr","date"' . "\n";

# Suck rediscovery fileunit metadata into hash for later processing
open(my $datafile, "<", "/Users/arubin06/UNIPHOTO.csv");
my $parser = Text::CSV::Simple->new;
$parser->field_map(qw/fileunit coll_nbr creator title/);
my @data = $parser->read_file($datafile);

# Start traversal through directory tree and call process_image() on each JPG
find(\&process_image, $startdir);

sub process_image {

  if ($_ =~ /\.JPG$/i) {

    # Extract relevant metadata from fileunit CSV file

    # Grab unique elements from filename to match against fileunit titles
    $_ =~ /(\d{6})_(\w{3})_(\w{3})/;
    my $job = "$1 $2 $3" ;


    # Cycle through rows in the fileunit CSV file and grab the collection number and creator
    my $creator;
    my $coll_nbr;
    foreach(@data) {
      if ($_->{'title'} =~ /$job/i) {
	$coll_nbr = "$_->{'coll_nbr'}-$_->{'fileunit'}";
	$creator = $_->{'creator'};
      }
    }

    # Create exiftool object and extract image metadata
    my $exifTool = new Image::ExifTool;
    my $image_file = $_;
    $exifTool->ExtractInfo($image_file);

    # Extract and format date information
    # my $date = $exifTool->GetValue('Date Created');
    # $date =~ s/:/-/g;

    # Extract and format description
    my $description = $exifTool->GetValue('Caption-Abstract');
    $description =~ s/^(\d+).+ -- //;
    my $date = $1;
    $description =~ s/Do not reproduce.+//;



    # We're using the first sentence of the description of the title so parse out
    # the first sentence and make that the title. We're also appending the photo #.
    my @sentences = get_sentences($description);
    $_ =~ /(\d+)\.JPG/i;
    my $photo_num = $1;
    my $title = "$sentences[0][0] Photo $photo_num";

    # Create an md5 hash of the image
    my $md5 = md5hex($image_file);

    # Add extracted metadata to a line of the CSV output
    print $out "\"$image_file\",\"$md5\",\"$title\",\"$description\",\"$creator\",\"$coll_nbr\",\"$date\"\n";
  }
}

sub md5hex {
  my $file = $_[0];
  open(FILE, $file) or die $!;
  return Digest::MD5->new->addfile(*FILE)->hexdigest;
}


