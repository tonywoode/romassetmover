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
#use diagnostics;
require Choice;
require CheckInputs;

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
my ($removedir_ref, $inputdir_ref, $invalid_input) = CheckInputs($inputfile, $output_dir_root, @inputdir); 	#Regurgitate your inputs and sort out any zips
my @removedirs = @$removedir_ref; @inputdir = @$inputdir_ref; 		#dereference the above arrays - first holds index of any folders to remove at the end....
if ($invalid_input) { # if there was a problem, get rid of any work done so far....
		print "Sorry the input dir $invalid_input can't be reached, exiting\n";
		if (@removedirs) { RemoveTempDirs($output_dir_root, \@removedirs, \@inputdir);	}
		die "Quit: One of the input dirs isn't reachable\n";
	}
my ($optype, $filetype) = OpChoice(%filetypes); 		#What are we doing and what filetype does that mean we'll look for?
print "Simulate by default (just hit return), or enter '1' now to COPY\t";
my ($copy ) 			= Choice();						#are we copying or not?
OpenFileDirs($output_dir_root, $optype, $copy);			#we name the output files and folders by operation type
my ($dat_line) 			= ParseQPFile();				#we understand what a QP datafile looks like
my($there, $notthere);									#sigh...need to init before the report loop
while (my $line = <INPUTDATFILE> ) {					#we scan for the roms in the input, report what we found, and copy if appropriate
	   my ( $foundpath, $mamename, $parent, $found_index ) = scanLine($line, $dat_line, $filetype, $optype, @inputdir );
	   Report($foundpath, $mamename,$parent, $found_index, $there, $notthere);
	   unless ($optype eq 'Roms' && $parent == 1) {		#now copy - never copy a parent rom as child name
			   if ($copy && $foundpath ne '') { Copy($output_dir_root, $optype, $parent, $foundpath, $mamename); }
	   }
}

CloseFileDirs();
print "\nFinished\n";
if (@removedirs) { RemoveTempDirs($output_dir_root, \@removedirs, \@inputdir);	}#pass references to arrays


#SUBS--------------------------------------------------------------------

sub CheckForZips {
	my ($index, @inputdir) = @_;
	my $index_removedir;
	
	my ($name, $path, $ext) = ( fileparse($inputdir[$index], qr/\.[^.]*/) );
	#print "ext is\t$ext\n"; #print "name is\t$name\n"; #print "path is\t$path\n";
	$ext = lc("$ext");
	if ($ext eq '.zip' || $ext eq '.7z') { 
		($index_removedir, @inputdir) = UnZip($index, $name, @inputdir); 
	}
	return ($index_removedir, @inputdir)#pass up the details of any replaced indexes so we can delete the dir later....
}

sub UnZip { #Uncompress zip archive at this array index, REPLACE the array index with the new loaction, flag theres a folder to delete at the end
	my ($index, $name, @inputdir) = @_; 
	
	my $unzip_dir = "$output_dir_root\\deleteme\\$name";
	print "\t$inputdir[$index] is an archive file\n\tMade temp dir at $unzip_dir\nUnzipping...";
	
	my $output = `\"$SEVEN_ZIP_PATH\" -y e \"$inputdir[$index]\" -o\"$unzip_dir\"`;		#https://uk.answers.yahoo.com/question/index?qid=20130128061122AAIubF5
																#note the -o must touch the output dir. its a 7zip thing not perl.  -y assumes yes to all promps
	if ($output =~ /Everything is Ok/g){ print "\nUnzip Complete - All OK\n"; }
	else{ die "\nSomething went wrong with the Unzip, exiting (try unzipping it yourself)\n"; } 
	
	$inputdir[$index]= $unzip_dir;			#now we have the zip, we have to change the array
	
	my $index_removedir = $index; 			#we'll remove the folder at this location when we're done
	return ($index_removedir, @inputdir); 	#...so return that index and the new dir
}	

sub OpChoice{
	my %filetypes = @_; #all we neeed is a list of filetypes and user input
	
	my ($optype, $filetype);
	my @menu_array; foreach my $keys (keys %filetypes) { push @menu_array, $keys }; 					#push the keys into array for the menu
	print "\nWhat do you want to compare?\n";
    for ( my $index = 0 ; $index < $#menu_array + 1 ; $index++ ) { print "\n\t$index)$menu_array[$index]\n"; }
    my $menu_item = <STDIN>;
    if ( $menu_item =~ /^[\+]?[0-$#menu_array]*\.?[0-$#menu_array]*$/ && $menu_item !~ /^[\. ]*$/ ){    #if its a number, and a number from the menu...
        $optype = $menu_array[$menu_item]; print "\nYou chose $optype\t";      	  						#we get our operation type...
		$filetype = $filetypes{$optype}; print "So I'm going to look for:\t$filetype\n\n";
	} 
    else { die "\nNo, that's not sensible. Try again with a choice that's in the menu\n"; }
    return $optype, $filetype;
}


sub OpenFileDirs {
	my ($output_dir_root, $optype, $copy) = @_; # need to know the root output dir, the type of asset to name folders, and whether we are copying
	
	open( INPUTDATFILE, $inputfile ) or die "Cannot open input dat file\n";
	my $havefile = "$output_dir_root\\Have$optype.txt"; open( HAVEFILE, ">$havefile" );
	my $missfile = "$output_dir_root\\Miss$optype.txt"; open( MISSFILE, ">$missfile" );
    my $parentchildfile = "$output_dir_root\\ParentChild$optype.txt"; open( PARENTCHILDFILE, ">$parentchildfile" );
	if ($copy) {my $copyfile = "$output_dir_root\\Copy$optype.txt"; open( COPYFILE, ">$copyfile" ); }
	#All global variables, nothing to return
}

sub ParseQPFile {	
    my $line = <INPUTDATFILE>; chomp $line;
    die "Quickplay data file not valid\n" if ( not $line =~ /ROM DataFile Version : / );
    my $QPS        = chr(172);          		#Quickplay's separator is ¬
    my $qp_pattern = "([^$QPS]*)$QPS";  		#...so a Quickplay romdata entry consists of this pattern
    my $dat_line 	   = "$qp_pattern" x 19; 	#...and a line of Quickplay romdata consits of that entry repeated 19 times
	return $dat_line;
}

sub scanLine {#need a line of romdata, a line format, a directory the files are in and their type, and the operation
	my($line, $dat_line, $filetype, @inputdir ) = @_;
	
    chomp $line;
    if ( $line =~ /^$dat_line/ ) {
		my $mamename   = $2;    #the name of the mame asset we're looking for is the 3rd field
        my $mameparent = $3;    #that rom's parent is the 4th		
		
		my $found_index = -1;
		my $parent = 0;			
        my $foundpath = '';
		
		print "\nScanning...\n";
			
		MAMESEARCH:until ($foundpath) {
              foreach my $path (0 .. $#inputdir) {	  
                    if		( $mamename ne '' && -e "$inputdir[$path]\\$mamename$filetype" ) { 
							$foundpath = "$inputdir[$path]\\$mamename$filetype"; 
							$found_index = $path; 
							last MAMESEARCH;
					}
					elsif	( $mameparent ne '' && -e "$inputdir[$path]\\$mameparent$filetype" ){
							$parent = 1; 
							$foundpath = "$inputdir[$path]\\$mameparent$filetype"; 
							$found_index = $path; 
							last MAMESEARCH;
					}   
              } 
		last MAMESEARCH; #$foundpath will be ''
		} 
	return $foundpath, $mamename, $parent, $found_index; #give back the path, and some less important stuff for reporting
	}
}

sub Report {
	my ($foundpath, $mamename, $parent, $found_index) = @_; #need a whole bunch of info for logging
	
	if ($foundpath eq '') { 
		$notthere++; 
		print "Can't find\t:\t$mamename\n"; print MISSFILE "Can't find\t=\t$mamename\n"; 
		}
	if ($foundpath ne '') { 
		$there++; 
		if 		($parent == 0) {
				printf HAVEFILE ( "%-15s %-25s %-15s", "$mamename", "Found Child in path $found_index", " = $foundpath\n" );
		}
		elsif 	($parent == 1) {
				printf PARENTCHILDFILE ( "%-15s %-25s %-15s", "$mamename", "No child, but Parent is in path$found_index", " = $foundpath\n" );
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
		print COPYFILE "Copying $foundpath to $outputfile\n"; copy $foundpath, $outputfile; 
}

sub CloseFileDirs {
    close(INPUTDATFILE);
    close(HAVEFILE);
    close(PARENTCHILDFILE);
    close(MISSFILE);
    close(COPYFILE);
}

sub RemoveTempDirs {
	my ($output_dir_root, $removedirs_ref, $inputdir_ref) = @_; #taking in two array references
	my @removedirs = @$removedirs_ref; my @inputdir = @$inputdir_ref; #dereferencing them
	foreach my $index (0 .. $#removedirs) {
		my $index_of_path = $removedirs[$index];
		print "\nOk to remove temp dir?: $inputdir[$index_of_path]\n1 for yes\t";
		my ($delete) = Choice();
		if ($delete) { remove_tree($inputdir[$index_of_path]); }
	}
	if ( -e "$output_dir_root\\deleteme") { remove_tree	"$output_dir_root\\deleteme" } #we made a dir to keep the temps in, delete it at the end...
}
