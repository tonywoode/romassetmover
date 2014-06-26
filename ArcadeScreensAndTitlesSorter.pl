#"C:\Perl64\bin\perl.exe" -w
#
# ArcadeSScreens and Titles sorter ensures that there is "supplemetary" folder screens and title files that are in a non-mame set and aren't in mame's assets.
#   Its use is so we don't have duplicate screenshots displaying in Quickplay frontend: In QuickPlay, ROMS CAN be standalone (and probably SHOULD be),
# 	and Icons are standalone (though can be in a shared folder, but probably shouldn't be). Screens and Titles as assets though, WILL display dupes
# 	if they aren't unique since all arcade systems are (and should be) collected under the system namespace "arcade". So if you have a full set of screenshots 
#   for Mame, and a full set of screenshots for your other arcader set, this script ensures you have a folder of screens or titles that are "supplementary" to Mame 
#
# So this script simply does an AB comparison and moves to C: A is our Mame asset folder, B is our Set's asset folder. 
#   Any unique names found in B that aren't in A will get moved to C. Once again we must deal with zips and 7zips as inputs, and clear them up.
#
#use diagnostics;
use strict;
use warnings;

#the subs we share
use ArcadeTools::Shared ('CheckInputs','RemoveTempDirs','OpChoice','Choice','SearchUniqInB','Copy','Report');

my $SEVEN_ZIP_PATH = 'C:\Program Files\7-Zip\7z.exe';

my ($inputdirsA, $inputdirsB, $output_dir_root);
##### INPUT YOUR SEARCH DIRECTORIES HERE #####
undef $ARGV[0]? $output_dir_root = $ARGV[0] : $output_dir_root = do 'Outputdir.txt';;  #output dir is the cmd arg or what's here

##### INPUT YOUR ASSET AND FILTYPES IN AssetTypes_Filetypes.txt ######
my %full_filetypes = do 'AssetTypes_Filetypes.txt'; my %filetypes;
#But for this script we're only interested in what you've put for screens and titles
$filetypes{"Screens"} = $full_filetypes{"Screens"};
$filetypes{"Titles"}  = $full_filetypes{"Titles"};

##### Main program #####
print "\n\n" . "*" x 35 . "\n\nArcade Moving tool: Screens\\Titles\n\n" . "*" x 35 . "\n";
print "\n***I'll only consider first 2 paths in inputdirs, and assets Screens/Titles***\n\n";
my @allinputdirs = do 'ArcadeScreensAndTitlesSorter_Inputdirs.txt'; my @inputdirs;
$inputdirs[0] = $allinputdirs[0]; $inputdirs[1] = $allinputdirs[1];

my ($removedir_ref, $inputdirs_ref, $invalid_input) = CheckInputs($SEVEN_ZIP_PATH, "not relevant", $output_dir_root, @inputdirs);
my @removedirs = @$removedir_ref; @inputdirs = @$inputdirs_ref; #dereference the above arrays - first holds index of any folders to remove at the end.... 		

if ($invalid_input) { # if there was a problem, get rid of any work done so far....
		print "Sorry the input dir $invalid_input can't be reached, exiting\n";
		if (@removedirs) { RemoveTempDirs($output_dir_root, \@removedirs, \@inputdirs);	}
		die "Quit: One of the input dirs isn't reachable\n";
	}

#What are we doing and what filetype does that mean we'll look for?	
my ($optype, $filetype) = OpChoice(%filetypes);

#are we copying or not?
print "Simulate by default (just hit return), or enter '1' now to COPY\t";
my ($copy ) = Choice();	

#we name the output files and folders by operation type
my ($HAVEFILE, $MISSFILE, $COPYFILE) = OpenFileDirs($output_dir_root, $optype);

#now do the comparison of directories. We'll just log as we're going along...
my %uniq_in_target = SearchUniqInB($filetype, $HAVEFILE, $MISSFILE, @inputdirs);

if ( $copy && (keys %uniq_in_target != 0) ) { #if we found something and chose to copy
	while ( my ($key, $value) = each(%uniq_in_target) ) {
			my $foundpath = $value;
			my $mamename = $key; #actually it becomes filename as we include a file extension in these keys, hence we send nothing as filetype
			Copy($COPYFILE, $output_dir_root, $optype, 0, $foundpath, $mamename, ''); #Parent is false as we aren't thinking about parernt/child
	}
}

CloseFileDirs();
print "\nFinished\n";

#did we unarchive temporarily? remove if so
if (@removedirs) { RemoveTempDirs($output_dir_root, \@removedirs, \@inputdirs);	}#pass references to arrays

print "\nExiting\n";

#LOCAL SUBS--------------------------------------------------------------------
sub OpenFileDirs {
	my ($output_dir_root, $optype) = @_; # need to know the root output dir, the type of asset to name folders, and whether we are copying
		
	#boiler plate opening of the filetypes
	my $havefile = "$output_dir_root\\Have$optype.txt"; open(my $HAVEFILE, ">", $havefile) || die "Couldn't open '".$havefile."' for reading because: ".$!;
	my $missfile = "$output_dir_root\\Miss$optype.txt"; open(my $MISSFILE, ">", $missfile) || die "Couldn't open '".$missfile."' for reading because: ".$!;
	my $copyfile = "$output_dir_root\\Copy$optype.txt";	open(my $COPYFILE, ">", $copyfile) || die "Couldn't open '".$copyfile."' for reading because: ".$!;
	
	return ($HAVEFILE, $MISSFILE, $COPYFILE);
}
	
sub CloseFileDirs {
    close($HAVEFILE);
    close($MISSFILE);
    close($COPYFILE);
}
