#"C:\Perl64\bin\perl.exe" -w
#
# ArcadeSupersetMover.pl will create standalone assets for arcade systems. In QuickPlay frontend, ROMS CAN be standalone (and probably SHOULD be),
# 	and Icons are standalone (though can be in a shared folder, but probably shouldn't be). Screens and Titles as assets though, WILL display dupes
# 	if they aren't unique.
#
# So this script simply does an AB comparison and moves to C: A is our
# 	Mame asset folder, B is our Set's asset folder. Any unique names found in B that aren't in A will
#	get moved to C. Once again we must deal with zips and 7zips as inputs
#
#use diagnostics;
use strict;
use warnings;

#the subs we share
use ArcadeTools::Shared ('CheckInputs','RemoveTempDirs','OpChoice','Choice','ParseQPFile','ScanLine','Copy','Report');

my $SEVEN_ZIP_PATH = 'C:\Program Files\7-Zip\7z.exe';

my ($inputdirA, $inputdirB, $output_dir_root);
##### INPUT YOUR SEARCH DIRECTORIES HERE #####
undef $ARGV[0]? $inputdirA = $ARGV[0] : $inputdirA = 'F:\Arcade\MAME\mameui\snap\snap.zip'; #InputA = first cmd arg or what's here
undef $ARGV[1]? $inputdirB = $ARGV[1] : $inputdirB = 'F:\Arcade\SCREENSHOTS\FBA_nonMAME_screenshots';  #InputB = 2nd cmd arg or what's here
undef $ARGV[2]? $output_dir_root = $ARGV[2] : $output_dir_root = 'F:\\Arcade\\TRANSIT';  #output dir is the 3rd cmd arg or what's here

##### INPUT YOUR ASSET AND FILTYPES HERE ######
my %filetypes = (       
        "Screens" => ".png",
        "Titles"  => ".png",
);

##### Main program #####
my @inputdir;
push @inputdir, $inputdirA;
push @inputdir, $inputdirB;
my ($removedir_ref, $inputdir_ref, $invalid_input) = CheckInputs($SEVEN_ZIP_PATH, "not relevant", $output_dir_root, @inputdir);
my @removedirs = @$removedir_ref; @inputdir = @$inputdir_ref; #dereference the above arrays - first holds index of any folders to remove at the end.... 		
print @inputdir;


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


