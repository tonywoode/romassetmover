#!/usr/bin/perl -w
#
# Takes as inputs: a quickplay datfile, and a collection of dir paths where mame assets are.
# 	In order, it tries to find the mame names of the items in the datfile in each path. It can then copy the assets found to an output dir.
#
# We deal with zips AND 7Zips by using 7zip to unpack
#
# Because mame-roms have a parent/child relationship, if we don't find the asset, we try and find it's parent and use its asset. (That may or may not
# 	be helpful so its stored in a subfolder. It certainly ISN'T helpful for the ROM itself so we turn it off (we don't want Street Fighter 2 Brazil to 
# 	turn out to be Street Fighter 2 World - the point of the parent/child relationship is to ditinguish them)
#	use diagnostics;
use strict;
use warnings;

#the subs we share
use ArcadeTools::Shared ('CheckInputs','RemoveTempDirs','OpChoice','Choice','ParseQPFile','ScanLine','Copy','Report');

my $SEVEN_ZIP_PATH = 'C:\Program Files\7-Zip\7z.exe';

my ($inputfile, $output_dir_root);
##### INPUT YOUR SEARCH DIRECTORIES HERE #####
undef $ARGV[0]? $inputfile = $ARGV[0] 		: $inputfile = do 'Inputdatfile.txt'; #Input file = first cmd arg, else what's in that txt file...
undef $ARGV[1]? $output_dir_root = $ARGV[1] : $output_dir_root = do 'Outputdir.txt';  #output dir is the 2nd cmd arg or what's in that txt file...

my @inputdirs = do 'Inputdirs.txt';

##### INPUT YOUR ASSET AND FILTYPES IN AssetTypes_Filetypes.txt ######
my %filetypes = do 'AssetTypes_Filetypes.txt';

##### Main program #####
print "\n\n" . "*" x 30 . "\n\n Romdata Asset Matching Tool\n\n" . "*" x 30 . "\n\n";
#First regurgitate your inputs and sort out any zips
my ($removedir_ref, $inputdirs_ref, $invalid_input) = CheckInputs($SEVEN_ZIP_PATH, $inputfile, $output_dir_root, @inputdirs); 	
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
my ($copy ) 			= Choice();						

#we name the output files and folders by operation type
my ($INPUTDATFILE, $HAVEFILE, $MISSFILE, $PARENTCHILDFILE, $COPYFILE) = OpenFileDirs($output_dir_root, $optype);

#we learn what a QP datafile looks like
my ($dat_line) 			= ParseQPFile($INPUTDATFILE);	

#we scan for the roms in the input, report what we found, and copy if appropriate
my ($there, $notthere, $present); #need to init before the report loop, present is a boolean passed to the sub from which we keep count
while (my $line = <$INPUTDATFILE> ) {					
		my ( $foundpath, $mamename, $parent, $found_index ) = ScanLine($line, $dat_line, $filetype, $optype, @inputdirs );
		#TODO: splitting out logging from scanning got a little messy here...is either module worthwhile standalone?
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
if (@removedirs) { RemoveTempDirs($output_dir_root, \@removedirs, \@inputdirs);	}#pass references to arrays

print "\nExiting\n";


#LOCAL SUBS--------------------------------------------------------------------
sub OpenFileDirs {
	my ($output_dir_root, $optype) = @_; # need to know the root output dir, the type of asset to name folders, and whether we are copying
	
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


