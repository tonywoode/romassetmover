#!/usr/bin/perl -w
#
# This program takes a quickplay datfile, and a collection of directory paths where mame assets are, as inputs. In order, it tries to find the mame names of the
# items in the datfile in each path. It can then copy the assets found to an output dir.
#
# Because mame-roms have a parent/child relationship, if we don't find the asset, we will try and find it's parent and use its asset. (That may or may not
# be helpful so its stored in a subfolder. It certainly ISN'T helpful for the ROM itself so we turn it off (we don't want Street Fighter 2 Brazil to turn out to be Street Fighter 2 World - the
# point of the parent/child relationship is to ditinguish them)

#use strict;
#use warnings;
use File::Copy qw(copy);
use File::Path qw(make_path);
sub OpChoice;
sub SimChoice;
sub OpenFileDirs;
sub ParseQPFile;

$INPUTFILE = $ARGV[0];
# INPUT YOUR VARIABLES HERE
#--------------------------------------------------------------------------
@INPUTDIR = ( #input dirs - no trailing \ please!!!!
	'F:\Arcade\TRANSIT\UNZIP\MAMESCREENIES',
	'F:\Arcade\SCREENSHOTS\FBA_nonMAME_screenshots',
	'F:\Sega Games\HazeMD\HazeMD\snap',
	'F:\Arcade\SCREENSHOTS\Winkawaks_NONMAME_screenshots',
);
$OUTDIR = "F:\\Arcade\\TRANSIT"; #Output dir
#--------------------------------------------------------------------------


print "\n\n" . "*"x30 . "\n\n Romdata Asset Matching Tool\n\n" . "*"x30 . "\n\n";
$INPUTFILE eq ''? die "Quiting - You didn't pass me an input file" : print "Input file set to:\n $INPUTFILE\n\n"; 
$OUTDIR eq ''? die "Quiting - You didn't program an output dir" : print "Output directory set to:\n $OUTDIR\n\n";
if (scalar @INPUTDIR == 0) { die "Quiting - You didn't pass me any input directories"; }
else { foreach $index ( 0 .. $#INPUTDIR ) { print "Input directory $index set to $INPUTDIR[$index]\n"; } }

#Ask what we're doing
OpChoice;
SimChoice;
OpenFileDirs;
ParseQPFile;


#Subroutines
#------------------------------------------------------------------------
sub OpChoice { #What are we doing and what filetype does that mean we'll look for?
my @menu_array=("Roms","Screens","Titles","Icons");
print "\nWhat do you want to compare?\n";
for ($index=0;$index<$#menu_array+1;$index++){ print "\n\t$index)$menu_array[$index]\n"; }
$menu_item = <STDIN>;
if ($menu_item =~ /^[\+]?[0-3]*\.?[0-3]*$/ && $menu_item !~ /^[\. ]*$/ ) { #if its a number between 0 and 3
	$opType = $menu_array[$menu_item]; print "\nYou chose $opType\t"; } #We get our operation type...
else { die "\nNo, that's not sensible. Try again with a choice that's in the menu\n"; }
	
%fileTypes = (
	"Roms"   => ".zip",
	"Screens" => ".png",
	"Titles"   => ".png",
	"Icons" => ".ico",
);	

$fileType = $fileTypes{$opType};
$OUTPUTDIR = "$OUTDIR\\$opType"; #SET THE OUTPUT DIRECTORY BASED ON OPTYPE NAME
print "So I'm going to look for:\t$fileType\n\n";
}

#---------------------------------------------------------------------------
sub SimChoice { #Give user choice of behaviour
	print "Simulate by default (just hit return), or enter '1' now to COPY\t";	
	CHOICE: while ( $copy = <STDIN> ) {
			chomp($copy);
			if ( ( uc($copy) eq uc("1") ) || ( $copy eq "" ) ) 
				{ last CHOICE ; }
			else {
				print "\nYou typed:\t$copy.\n\nTry again - type either \"1\" or press Return:\t\n\n";
				announce;
				}
			}	
}

#------------------------------------------------------------------------
sub OpenFileDirs {
if ($copy) { make_path $OUTPUTDIR;}
if ($copy) { make_path "$OUTPUTDIR\\Parentchild";} # make this dir for image types in case we need it later
$HAVEFILE = "$OUTDIR\\Have$opType.txt";
$PARENTCHILDFILE = "$OUTDIR\\ParentChild$opType.txt";
$MISSFILE = "$OUTDIR\\Miss$opType.txt";
$QPS = chr(172); #Quickplay's separator is ¬

open(QPDATFILE, $INPUTFILE) or die "Cannot open Quickplay dat file\n";
open(HAVEFILE, ">$HAVEFILE");
open(PARENTCHILDFILE, ">$PARENTCHILDFILE");
open(MISSFILE, ">$MISSFILE");
}

#------------------------------------------------------------------------
sub ParseQPFile {
	# check QP Data file is valid
	$line=<QPDATFILE>;
	chomp $line;
	die "Quickplay data file not valid\n" if (not $line =~ /ROM DataFile Version : /);

	while ($line=<QPDATFILE>)
	{
		chomp $line;
		if ($line =~ /^([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS([^$QPS]*)$QPS/)
		{
			$mameName = $2; #mamename
			$mameParent = $3; #parent romname
			
			$OUTPUTDIR = "$OUTDIR\\$opType"; #previous image may have changed the output dir to \\parentchild
			
			$path1 = "$INPUTDIR[0]\\$mameName$fileType";			
			$path2 = "$INPUTDIR[1]\\$mameName$fileType";
			$path3 = "$INPUTDIR[2]\\$mameName$fileType";
			$path4 = "$INPUTDIR[3]\\$mameName$fileType";
			#if its not held as the mamename, we try the parent name. this may be blank....
			$path5 = "$INPUTDIR[0]\\$mameParent$fileType";
			$path6 = "$INPUTDIR[1]\\$mameParent$fileType";
			$path7 = "$INPUTDIR[2]\\$mameParent$fileType";
			$path8 = "$INPUTDIR[3]\\$mameParent$fileType";
			
			if 	  ($path1 ne '' && -e $path1) {$there ++; $foundPath = $path1;  printf HAVEFILE  ("%-15s %-15s %-25s %-15s", "$mameName", "Found", "Child is in path1"," = $path1\n"); } 
			elsif ($path2 ne '' && -e $path2) {$there ++; $foundPath = $path2;	printf HAVEFILE  ("%-15s %-15s %-25s %-15s", "$mameName", "Found", "Child is in path2"," = $path2\n"); } 
			elsif ($path3 ne '' && -e $path3) {$there ++; $foundPath = $path3;	printf HAVEFILE  ("%-15s %-15s %-25s %-15s", "$mameName", "Found", "Child is in path3"," = $path3\n"); } 
			elsif ($path4 ne '' && -e $path4) {$there ++; $foundPath = $path4;	printf HAVEFILE  ("%-15s %-15s %-25s %-15s", "$mameName", "Found", "Child is in path4"," = $path4\n"); } 
			# again, try the parent if we don't find it....its the only way to be sure...but we don't want to check if parent is blank
			# but here's the thing: do we copy the parent as the child rom's name? Theoretically we don't need, but then we WILL come across
			# instances where the MAME parent gets renamed in a later version. We certainly don't want to copy parent ROMS with child names, that would
			# be a disaster....lets put these in a subdir for now "parentchild"
			elsif ($opType ne 'Roms' && $path5 ne '' && -e $path5) {$there ++; $foundPath = $path5; $OUTPUTDIR = "$OUTPUTDIR\\parentchild"; printf PARENTCHILDFILE ("%-15s %-15s %-25s %-15s", "$mameName", "Missing", "Parent is in path5"," = $path5\n"); }
			elsif ($opType ne 'Roms' && $path6 ne '' && -e $path6) {$there ++; $foundPath = $path6; $OUTPUTDIR = "$OUTPUTDIR\\parentchild"; printf PARENTCHILDFILE ("%-15s %-15s %-25s %-15s", "$mameName", "Missing", "Parent is in path6"," = $path6\n"); }
			elsif ($opType ne 'Roms' && $path7 ne '' && -e $path7) {$there ++; $foundPath = $path7; $OUTPUTDIR = "$OUTPUTDIR\\parentchild"; printf PARENTCHILDFILE ("%-15s %-15s %-25s %-15s", "$mameName", "Missing", "Parent is in path7"," = $path7\n"); }
			elsif ($opType ne 'Roms' && $path8 ne '' && -e $path8) {$there ++; $foundPath = $path8; $OUTPUTDIR = "$OUTPUTDIR\\parentchild"; printf PARENTCHILDFILE ("%-15s %-15s %-25s %-15s", "$mameName", "Missing", "Parent is in path8"," = $path8\n"); }
			
			else { $notThere ++; print "Can't find\t=\t$mameName\n"; print MISSFILE "Can't find\t=\t$mameName\n"}
			
			#now do it - we hopefully never copy a parent rom as child name....
			if ($copy) { print HAVEFILE "Copying $foundPath to $OUTPUTDIR\\$mameName$fileType\n"; copy $foundPath, "$OUTPUTDIR\\$mameName$fileType"; }
		}
		
	}
	#print "\nnumber of mamegames present as child or parent = $there";
	printf "%-50s %10u", "\nnumber of mamenames present as child or parent:\t", (defined $there ? "$there" : "0");
	#defined $notThere ? print "\nnumber of files not present = $notThere" : print "\nNo files not found" ;
	printf "%-46s %10u", "\nNumber of mamenames not found:\t", (defined $notThere ? "$notThere" : "0");

	close(HAVEFILE);
	close(PARENTCHILD);
	close(MISSFILE);
}