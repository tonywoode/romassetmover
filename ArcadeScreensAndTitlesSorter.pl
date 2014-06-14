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
use File::Find;
use List::MoreUtils qw(uniq);

#the subs we share
use ArcadeTools::Shared ('CheckInputs','RemoveTempDirs','OpChoice','Choice','ParseQPFile','ScanLine','Copy','Report');

my $SEVEN_ZIP_PATH = 'C:\Program Files\7-Zip\7z.exe';

my ($inputdirsA, $inputdirsB, $output_dir_root);
##### INPUT YOUR SEARCH DIRECTORIES HERE #####
undef $ARGV[0]? $output_dir_root = $ARGV[0] : $output_dir_root = 'F:\\Arcade\\TRANSIT';  #output dir is the cmd arg or what's here

##### INPUT YOUR ASSET AND FILTYPES HERE ######
my %full_filetypes = do 'Filetypes.txt'; my %filetypes;
$filetypes{"Screens"} = $full_filetypes{"Screens"};
$filetypes{"Titles"}  = $full_filetypes{"Titles"};

##### Main program #####
print "\n\n" . "*" x 30 . "\n\nArcade Moving tools for Screens and Titles\n\n" . "*" x 30 . "\n";
print "\n***I'll only consider the first TWO paths in inputdirs, and the first TWO filetypes***\n\n";
my @allinputdirs = do 'Inputdirs.txt'; my @inputdirs;
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
my ($copy ) 			= Choice();	

#we name the output files and folders by operation type
my ($HAVEFILE, $MISSFILE, $COPYFILE) = OpenFileDirs($output_dir_root, $optype);

my @uniq_in_target = SearchUniqInB($filetype, $HAVEFILE, $MISSFILE, @inputdirs);


sub SearchUniqInB{
	my ($filetype, $HAVEFILE, $MISSFILE, @inputdirs) = @_;
	#we scan for the roms in the input, report what we found, and copy if appropriate
	my (%files1, %files2);
	find(\&find_txt, $inputdirs[0]); #neither sub or wanted-> contrstucts would put filename in key and fullpath in value
	find(\&find_txt2, $inputdirs[1]);

	my @all = uniq(keys %files1, keys %files2);
	my @uniq_in_target;
	
	sub find_txt  { if ($File::Find::name =~ /$filetype$/ && -f ) { $files1{$_} = $File::Find::name; } }
	sub find_txt2 { if ($File::Find::name =~ /$filetype$/ && -f ) { $files2{$_} = $File::Find::name ; } }
	
	for my $file (@all) {
		if ($files1{$file} && $files2{$file} && $file ne '.') { #file exists in both dirs
			print $HAVEFILE "$file is in both dirs\n";
		}
		elsif ($files1{$file}) { #file only existsn in dir 1
			print $HAVEFILE "$file is in $inputdirs[0] and not in $inputdirs[1]\n";
		}
		else { #file only exists in dir 2
			print $MISSFILE "$file is in $inputdirs[1] and not in $inputdirs[0]\n";
			push @uniq_in_target, $files2{$file};
		}
	}
	return @uniq_in_target
}
#foreach my $keys (keys %files2) { push @menu_array, $keys };
print "here are the files that aren't in MAME: @uniq_in_target";            
#for each my $keys (@uniq)in_target) { push @


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
