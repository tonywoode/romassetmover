#!/usr/bin/perl -w
#
# Takes as inputs: a quickplay datfile, and a collection of dir paths where mame assets are.
# In order, it tries to find the mame names of the items in the datfile in each path. It can then copy the assets found to an output dir.
#
# Because mame-roms have a parent/child relationship, if we don't find the asset, we try and find it's parent and use its asset. (That may or may not
# be helpful so its stored in a subfolder. It certainly ISN'T helpful for the ROM itself so we turn it off (we don't want Street Fighter 2 Brazil to 
# turn out to be Street Fighter 2 World - the point of the parent/child relationship is to ditinguish them)

use strict;
use warnings;
use diagnostics;
require Choice;
require CheckInputs;
require CheckForZips;
require OpChoice;
require RemoveTempDirs;
require ScanLine;

use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Basename;

my $SEVEN_ZIP_PATH = 'C:\Program Files\7-Zip\7z.exe';

my ($inputfile, $output_dir_root);

##### INPUT YOUR SEARCH DIRECTORIES HERE #####
undef $ARGV[0]? $inputfile = $ARGV[0] 		: $inputfile = 'C:\Emulators\QUICKPLAY\qp\data\Arcade\FinalBurn Alpha\ROMDATA.dat'; #Input file = first cmd arg or what's here
undef $ARGV[1]? $output_dir_root = $ARGV[1] : $output_dir_root = 'F:\\Arcade\\TRANSIT';  #output dir is the 2nd cmd arg or what's here

my @inputdir = ( #yes you have to set these here - search dirs - no trailing \ please!!!!
    'F:\Arcade\MAME\mameui\snap\snap.zip',
    'F:\Arcade\SCREENSHOTS\FBA_nonMAME_screenshots',
    'F:\Sega Games\HazeMD\HazeMD\snap',
    'F:\Arcade\SCREENSHOTS\Winkawaks_NONMAME_screenshots',
);

##### INPUT YOUR ASSET AND FILTYPES HERE ######
my %filetypes = (       
        "Screens" => ".png",
        "Titles"  => ".png",
        "Icons"   => ".ico",
		"Roms"    => ".zip",
);


#Main program
my ($removedir_ref, $inputdir_ref, $invalid_input) = CheckInputs($SEVEN_ZIP_PATH, $inputfile, $output_dir_root, @inputdir); 	#Regurgitate your inputs and sort out any zips
my @removedirs = @$removedir_ref; @inputdir = @$inputdir_ref; 		#dereference the above arrays - first holds index of any folders to remove at the end....
if ($invalid_input) { # if there was a problem, get rid of any work done so far....
		print "Sorry the input dir $invalid_input can't be reached, exiting\n";
		if (@removedirs) { RemoveTempDirs($output_dir_root, \@removedirs, \@inputdir);	}
		die "Quit: One of the input dirs isn't reachable\n";
	}
my ($optype, $filetype) = OpChoice(%filetypes); 		#What are we doing and what filetype does that mean we'll look for?
print "Simulate by default (just hit return), or enter '1' now to COPY\t";
my ($copy ) 			= Choice();						#are we copying or not?
my ($INPUTDATFILE, $HAVEFILE, $MISSFILE, $PARENTCHILDFILE, $COPYFILE) = OpenFileDirs($output_dir_root, $optype, $copy);			#we name the output files and folders by operation type
my ($dat_line) 			= ParseQPFile($INPUTDATFILE);	#we understand what a QP datafile looks like
my($there, $notthere);									#sigh...need to init before the report loop
while (my $line = <$INPUTDATFILE> ) {					#we scan for the roms in the input, report what we found, and copy if appropriate
	   my ( $foundpath, $mamename, $parent, $found_index ) = ScanLine($line, $dat_line, $filetype, $optype, @inputdir );
	   Report($foundpath, $mamename,$parent, $found_index, $there, $notthere);
	   unless ($optype eq 'Roms' && $parent == 1) {		#now copy - never copy a parent rom as child name
			   if ($copy && $foundpath ne '') { Copy($output_dir_root, $optype, $parent, $foundpath, $mamename); }
	   }
}

CloseFileDirs();
print "\nFinished\n";
if (@removedirs) { RemoveTempDirs($output_dir_root, \@removedirs, \@inputdir);	}#pass references to arrays

#SUBS--------------------------------------------------------------------
sub OpenFileDirs {
	my ($output_dir_root, $optype, $copy) = @_; # need to know the root output dir, the type of asset to name folders, and whether we are copying
	
	open(my $INPUTDATFILE, "<", $inputfile) || die "Couldn't open '".$inputfile."' for reading because: ".$!;
	
	my $havefile = "$output_dir_root\\Have$optype.txt";
	open(my $HAVEFILE, ">", $havefile) || die "Couldn't open '".$havefile."' for reading because: ".$!;
	
	my $missfile = "$output_dir_root\\Miss$optype.txt";
	open(my $MISSFILE, ">", $missfile) || die "Couldn't open '".$missfile."' for reading because: ".$!;
	
    my $parentchildfile = "$output_dir_root\\ParentChild$optype.txt";
	open(my $PARENTCHILDFILE, ">", $parentchildfile) || die "Couldn't open '".$parentchildfile."' for reading because: ".$!;
	
	my $copyfile = "$output_dir_root\\Copy$optype.txt";		
	open(my $COPYFILE, ">", $copyfile) || die "Couldn't open '".$copyfile."' for reading because: ".$!;
	
	return ($INPUTDATFILE, $HAVEFILE, $MISSFILE, $PARENTCHILDFILE, $COPYFILE);
}

sub ParseQPFile {
	my ($INPUTDATFILE) = @_;
	
    my $line = <$INPUTDATFILE>; chomp $line;
    die "Quickplay data file not valid\n" if ( not $line =~ /ROM DataFile Version : / );
    my $QPS        = chr(172);          		#Quickplay's separator is ¬
    my $qp_pattern = "([^$QPS]*)$QPS";  		#...so a Quickplay romdata entry consists of this pattern
    my $dat_line 	   = "$qp_pattern" x 19; 	#...and a line of Quickplay romdata consits of that entry repeated 19 times
	return $dat_line;
}

sub Report {
	my ($foundpath, $mamename, $parent, $found_index) = @_; #need a whole bunch of info for logging
	
	if ($foundpath eq '') { 
		$notthere++; 
		print "Can't find\t:\t$mamename\n"; print $MISSFILE "Can't find\t=\t$mamename\n"; 
		}
	if ($foundpath ne '') { 
		$there++; 
		if 		($parent == 0) {
				printf $HAVEFILE ( "%-15s %-25s %-15s", "$mamename", "Found Child in path $found_index", " = $foundpath\n" );
		}
		elsif 	($parent == 1) {
				printf $PARENTCHILDFILE ( "%-15s %-25s %-15s", "$mamename", "No child, but Parent is in path$found_index", " = $foundpath\n" );
		}
	}
	printf "%-50s %10u", "\nnumber of mamenames present as child or parent:\t", ( defined $there ? 	  "$there" : "0" );
	printf "%-46s %10u", "\nnumber of mamenames not found:\t", 					( defined $notthere ? "$notthere" : "0" );
}
		
sub Copy {
	my ($output_dir_root, $optype, $parent, $foundpath, $mamename) = @_;
	
	my $this_outputdir = "$output_dir_root\\$optype"; make_path $this_outputdir;
	if ($parent == 1) { $this_outputdir .= "\\parentchild"; } make_path $this_outputdir;
		my $outputfile = "$this_outputdir\\$mamename$filetype";
		print "\nCopying...\n";
		print $COPYFILE "Copying $foundpath to $outputfile\n"; copy $foundpath, $outputfile; 
}

sub CloseFileDirs {
    close($INPUTDATFILE);
    close($HAVEFILE);
    close($PARENTCHILDFILE);
    close($MISSFILE);
    close($COPYFILE);
}


