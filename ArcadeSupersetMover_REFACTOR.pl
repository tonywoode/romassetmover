#!/usr/bin/perl -w
#
# Takes as inputs: a quickplay datfile, and a collection of dir paths where mame assets are.
# In order, it tries to find the mame names of the items in the datfile in each path. It can then copy the assets found to an output dir.
#
# Because mame-roms have a parent/child relationship, if we don't find the asset, we try and find it's parent and use its asset. (That may or may not
# be helpful so its stored in a subfolder. It certainly ISN'T helpful for the ROM itself so we turn it off (we don't want Street Fighter 2 Brazil to 
# turn out to be Street Fighter 2 World - the point of the parent/child relationship is to ditinguish them)
package ArcadeSupersetMover;


use strict;
use warnings;

use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Basename;

##### INPUT YOUR SEARCH DIRECTORIES HERE#####
my ($inputfile, $output_dir_root);
my $SEVEN_ZIP_PATH = 'C:\Program Files\7-Zip\7z.exe';

undef $ARGV[0]? $inputfile = $ARGV[0] 		: $inputfile = 'C:\Emulators\QUICKPLAY\qp\data\Arcade\FinalBurn Alpha\ROMDATA.dat'; #Input file is the first cmd arg or what's here
undef $ARGV[1]? $output_dir_root = $ARGV[1] : $output_dir_root = 'F:\\Arcade\\TRANSIT';  #output dir is the 2nd cmd arg or what's here

my @inputdir = ( #yes you have to set these here - search dirs - no trailing \ please!!!!
    'F:\Arcade\TRANSIT\UNZIP\MAMESCREENIES.7z',
    'F:\Arcade\SCREENSHOTS\FBA_nonMAME_screenshots',
    'F:\Sega Games\HazeMD\HazeMD\snap',
    'F:\Arcade\SCREENSHOTS\Winkawaks_NONMAME_screenshots',
);

#####INPUT YOUR ASSET AND FILTYPES HERE######
my %filetypes = (
        "Roms"    => ".zip",
        "Screens" => ".png",
        "Titles"  => ".png",
        "Icons"   => ".ico",
	);

#Main program
EchoInputs($inputfile, $output_dir_root, @inputdir); 	#Regurgitate your inputs and sort out any zips
my ($optype, $filetype) = OpChoice(%filetypes); 		#What are we doing and what filetype does that mean we'll look for?
my ($copy ) 			= SimChoice();					#are we copying or not?
OpenFileDirs($output_dir_root, $optype, $copy);			#we name the output files and folders by operation type
my ($dat_line) 			= ParseQPFile();				#we understand what a QP datafile looks like

my($there, $notthere);									#sigh...need to init before the report loop
while (my $line = <INPUTDATFILE> ) {					#we scan for the roms in the input, report what we found, and copy if appropriate
	   my ( $foundpath, $mamename, $parent, $found_index ) = scanLine($line, $dat_line, $filetype, $optype, @inputdir );
	   Report($foundpath, $mamename,$parent, $found_index);
	   unless ($optype eq 'Roms' && $parent == 1) {		#now copy - never copy a parent rom as child name
			   if ($copy && $foundpath ne '') { Copy($output_dir_root, $optype, $parent, $foundpath, $mamename); }
	   }
}

CloseFileDirs();
print "\nFinished\n";

#------------------------------------------------------------------------
#Subs

sub EchoInputs{
	my($inputfile, $output_dir_root, @inputdir) = @_; #need the inputs you set above
	
	print "\n\n" . "*" x 30 . "\n\n Romdata Asset Matching Tool\n\n" . "*" x 30 . "\n\n";
	$inputfile 				eq ''? die "Quiting - You didn't set an input file\n" : print "Input file set to:\n $inputfile\n\n";
	$output_dir_root 		eq ''? die "Quiting - You didn't set an output dir\n" : print "Output directory set to:\n $output_dir_root\n\n";
	if ( scalar @inputdir == 0 ) { die "Quiting - You didn't pass me any input directories\n"; }
	else { foreach my $index ( 0 .. $#inputdir ) { 
		print "Input directory $index set to $inputdir[$index]\n";  
		CheckForZips(@inputdir);
		}
	}
}

sub CheckForZips {
	my @inputdir = @_;
	
	foreach my $index ( 0 .. $#inputdir ) { 
			my ($name, $path, $ext) = ( fileparse($inputdir[$index], qr/\.[^.]*/) );
			#print "ext is\t$ext\n"; #print "name is\t$name\n"; #print "path is\t$path\n";
			$ext = lc("$ext");
			if ($ext eq '.zip' || $ext eq '.7z') { UnZip($index, $name, @inputdir); }
	}
	die;
}

sub UnZip {
	my ($index, $name, @inputdir) = @_; 
	#Goal is to uncompress the zip archive at this array index, and then REPLACE the array index with the new loaction, we'll also need to flag down that theres a folder to delete at the end
	
	#https://uk.answers.yahoo.com/question/index?qid=20130128061122AAIubF5
	#note the -o must touch the output dir. its a 7zip thing not perl.  -y assumes yes to all promps
	print "Unzipping $inputdir[$index]... to temp directory at $output_dir_root\\$name";
	
	my $output = `\"$SEVEN_ZIP_PATH\" -y e \"$inputdir[$index]\" -o\"$output_dir_root\\$name\"`; #we need to later delete that $name, somehow...
	if ($output =~ /Everything is Ok/g){ print "\nUnzip Complete - All OK\n"; }
	else{ die "\nSomething went wrong with the Unzip, exiting (try unzipping it yourself)\n"; } 
}	
	


sub OpChoice{
	my %filetypes = @_; #all we neeed is a list of filetypes and user input
	my ($optype, $filetype);
	my @menu_array; foreach my $keys (keys %filetypes) { unshift @menu_array, $keys }; 					#push the keys into array for the menu
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

sub SimChoice {
	my $copy;
	print "Simulate by default (just hit return), or enter '1' now to COPY\t";
	CHOICE: while ( $copy = <STDIN> ) {
				chomp($copy);
				if ( ( uc($copy) eq uc("1") ) || ( $copy eq "" ) ) { last CHOICE; }
				else { print "\nYou typed:\t$copy.\n\nTry again - type either \"1\" or press Return:\t\n\n"; }
			}
	return $copy
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
        my $mameparent = $3;    #that rom's parentis the 4th		
		
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
		print "Can't find\t:\t$mamename\n"; 
		print MISSFILE "Can't find\t=\t$mamename\n"; 
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
