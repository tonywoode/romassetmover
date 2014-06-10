#!/usr/bin/perl -w
#
# Takes as inputs: a quickplay datfile, and a collection of dir paths where mame assets are.
# In order, it tries to find the mame names of the items in the datfile in each path. It can then copy the assets found to an output dir.
#
# We deal with zips AND 7Zips by using 7zip to unpack
#
# Because mame-roms have a parent/child relationship, if we don't find the asset, we try and find it's parent and use its asset. (That may or may not
# be helpful so its stored in a subfolder. It certainly ISN'T helpful for the ROM itself so we turn it off (we don't want Street Fighter 2 Brazil to 
# turn out to be Street Fighter 2 World - the point of the parent/child relationship is to ditinguish them)
#use diagnostics;
use strict;
use warnings;
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Basename;

#the modules we've split out
require Modules::Choice;
require Modules::CheckInputs;
require Modules::CheckForZips;
require Modules::OpChoice;
require Modules::ParseQPFile;
require Modules::ScanLine;
require Modules::Report;
require Modules::Copy;
require Modules::RemoveTempDirs;

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

##### Main program #####

#First regurgitate your inputs and sort out any zips
my ($removedir_ref, $inputdir_ref, $invalid_input) = CheckInputs($SEVEN_ZIP_PATH, $inputfile, $output_dir_root, @inputdir); 	
my @removedirs = @$removedir_ref; @inputdir = @$inputdir_ref; #dereference the above arrays - first holds index of any folders to remove at the end.... 		

if ($invalid_input) { # if there was a problem, get rid of any work done so far....
		print "Sorry the input dir $invalid_input can't be reached, exiting\n";
		if (@removedirs) { RemoveTempDirs($output_dir_root, \@removedirs, \@inputdir);	}
		die "Quit: One of the input dirs isn't reachable\n";
	}

#What are we doing and what filetype does that mean we'll look for?	
my ($optype, $filetype) = OpChoice(%filetypes);

#are we copying or not?
print "Simulate by default (just hit return), or enter '1' now to COPY\t";
my ($copy ) 			= Choice();						

#we name the output files and folders by operation type
my ($INPUTDATFILE, $HAVEFILE, $MISSFILE, $PARENTCHILDFILE, $COPYFILE) = OpenFileDirs($output_dir_root, $optype, $copy);

#we learn what a QP datafile looks like
my ($dat_line) 			= ParseQPFile($INPUTDATFILE);	

#we scan for the roms in the input, report what we found, and copy if appropriate
my ($there, $notthere, $present); #need to init before the report loop, present is a boolean passed to the sub from which we keep count
while (my $line = <$INPUTDATFILE> ) {					
		my ( $foundpath, $mamename, $parent, $found_index ) = ScanLine($line, $dat_line, $filetype, $optype, @inputdir );
		($present) = Report($MISSFILE, $HAVEFILE, $PARENTCHILDFILE, $foundpath, $mamename,$parent, $found_index);
		if ($present == 1) { $there++; }
		if ($present == 0) {$notthere++;}
		printf "%-50s %10u", "\nnumber of mamenames present as child or parent:\t", ( defined $there ? 	  "$there" : "0" );
		printf "%-46s %10u", "\nnumber of mamenames not found:\t", 					( defined $notthere ? "$notthere" : "0" );	   
		unless ($optype eq 'Roms' && $parent == 1) {		#now copy - never copy a parent rom as child name
			   if ($copy && $foundpath ne '') { Copy($COPYFILE, $output_dir_root, $optype, $parent, $foundpath, $mamename, $filetype); }
	   }
}

CloseFileDirs();
print "\nFinished\n";

#did we unarchive temporarily? remove if so
if (@removedirs) { RemoveTempDirs($output_dir_root, \@removedirs, \@inputdir);	}#pass references to arrays

print "\nExiting\n";


#LOCAL SUBS--------------------------------------------------------------------
sub OpenFileDirs {
	my ($output_dir_root, $optype, $copy) = @_; # need to know the root output dir, the type of asset to name folders, and whether we are copying
	
	open(my $INPUTDATFILE, "<", $inputfile) || die "Couldn't open '".$inputfile."' for reading because: ".$!;
	
	#boiler plate opening of the four filetypes
	my $havefile = "$output_dir_root\\Have$optype.txt"; open(my $HAVEFILE, ">", $havefile) || die "Couldn't open '".$havefile."' for reading because: ".$!;
	my $missfile = "$output_dir_root\\Miss$optype.txt"; open(my $MISSFILE, ">", $missfile) || die "Couldn't open '".$missfile."' for reading because: ".$!;
    my $parentchildfile = "$output_dir_root\\ParentChild$optype.txt"; open(my $PARENTCHILDFILE, ">", $parentchildfile) || die "Couldn't open '".$parentchildfile."' for reading because: ".$!;
	my $copyfile = "$output_dir_root\\Copy$optype.txt";	open(my $COPYFILE, ">", $copyfile) || die "Couldn't open '".$copyfile."' for reading because: ".$!;
	
	return ($INPUTDATFILE, $HAVEFILE, $MISSFILE, $PARENTCHILDFILE, $COPYFILE);
}
	
sub CloseFileDirs {
    close($INPUTDATFILE);
    close($HAVEFILE);
    close($PARENTCHILDFILE);
    close($MISSFILE);
    close($COPYFILE);
}


