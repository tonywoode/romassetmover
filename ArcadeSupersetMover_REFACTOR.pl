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
sub CloseFileDirs;
sub SayWhatYouSee;

#--------------------------------------------------------------------------
# INPUT YOUR DIRECTORIES HERE

undef $ARGV[0]? $inputfile = $ARGV[0] : $inputfile = ''; #Input file is the first cmd arg or what's here
undef $ARGV[1]? $outdir = $ARGV[1] : $outdir = "F:\\Arcade\\TRANSIT";  #output dir is the 2nd cmd arg or what's here

@inputdir = (    #input dirs - no trailing \ please!!!!
    'F:\Arcade\TRANSIT\UNZIP\MAMESCREENIES',
    'F:\Arcade\SCREENSHOTS\FBA_nonMAME_screenshots',
    'F:\Sega Games\HazeMD\HazeMD\snap',
    'F:\Arcade\SCREENSHOTS\Winkawaks_NONMAME_screenshots',
);
#--------------------------------------------------------------------------
#Main program
SayWhatYouSee();
OpChoice();
SimChoice();
OpenFileDirs();
ParseQPFile();
CloseFileDirs();


#Subs
#------------------------------------------------------------------------
sub SayWhatYouSee {
	print "\n\n" . "*" x 30 . "\n\n Romdata Asset Matching Tool\n\n" . "*" x 30 . "\n\n";
	
	$inputfile eq ''? die "Quiting - You didn't set an input file" : print "Input file set to:\n $inputfile\n\n";
	$outdir    eq ''? die "Quiting - You didn't set an output dir" : print "Output directory set to:\n $outdir\n\n";
	if ( scalar @inputdir == 0 ) { die "Quiting - You didn't pass me any input directories"; }
	else { foreach $index ( 0 .. $#inputdir ) { print "Input directory $index set to $inputdir[$index]\n"; } }
}

#------------------------------------------------------------------------
sub OpChoice{    #What are we doing and what filetype does that mean we'll look for?
    
	my @menu_array = ( "Roms", "Screens", "Titles", "Icons" );
    
	print "\nWhat do you want to compare?\n";
    for ( $index = 0 ; $index < $#menu_array + 1 ; $index++ ) { print "\n\t$index)$menu_array[$index]\n"; }
    $menu_item = <STDIN>;
    if ( $menu_item =~ /^[\+]?[0-3]*\.?[0-3]*$/ && $menu_item !~ /^[\. ]*$/ ){    #if its a number between 0 and 3
        $opType = $menu_array[$menu_item]; print "\nYou chose $opType\t";      	  #we get our operation type...
		} 
    else { die "\nNo, that's not sensible. Try again with a choice that's in the menu\n"; }

    %fileTypes = (
        "Roms"    => ".zip",
        "Screens" => ".png",
        "Titles"  => ".png",
        "Icons"   => ".ico",
    );

    $fileType  = $fileTypes{$opType};
    $outputdir = "$outdir\\$opType";    #SET THE OUTPUT DIRECTORY BASED ON OPTYPE NAME
    print "So I'm going to look for:\t$fileType\n\n";
}

#---------------------------------------------------------------------------
sub SimChoice { #Give user choice of behaviour
    print "Simulate by default (just hit return), or enter '1' now to COPY\t";
	CHOICE: while ( $copy = <STDIN> ) {
				chomp($copy);
				if ( ( uc($copy) eq uc("1") ) || ( $copy eq "" ) ) { last CHOICE; }
				else { print "\nYou typed:\t$copy.\n\nTry again - type either \"1\" or press Return:\t\n\n"; }
			}
}

#------------------------------------------------------------------------
sub OpenFileDirs {
    if ($copy) { make_path $outputdir; }
    if ($copy) { make_path "$outputdir\\Parentchild"; }    # make this dir for image types in case we need it later
    open( QPDATFILE, $inputfile ) or die "Cannot open Quickplay dat file\n";
    $havefile = "$outdir\\Have$opType.txt"; open( HAVEFILE, ">$havefile" );
    $parentchildfile = "$outdir\\ParentChild$opType.txt"; open( PARENTCHILDFILE, ">$parentchildfile" );
    $missfile = "$outdir\\Miss$opType.txt"; open( MISSFILE, ">$missfile" );
    $copyfile = "$outdir\\Copy$opType.txt"; open( COPYFILE, ">$copyfile" );
}

#------------------------------------------------------------------------
sub ParseQPFile {
    $line = <QPDATFILE>;
    chomp $line;
    die "Quickplay data file not valid\n" if ( not $line =~ /ROM DataFile Version : / );    # check QP Data file is valid
    $QPS        = chr(172);          #Quickplay's separator is ¬
    $qp_pattern = "([^$QPS]*)$QPS";  #...so a Quickplay romdata entry consists of this pattern...
    $qp_line = "$qp_pattern" x 19; 	 #...thus a line of Quickplay romdata consits of that entry repeated 19 times

    print "\nScanning...\n";
    while ( $line = <QPDATFILE> ) {
        chomp $line;
        if ( $line =~ /^$qp_line/ ) {
            $mameName   = $2;    #mamename
            $mameParent = $3;    #parent romname

            $outputdir = "$outdir\\$opType"; #previous image may have changed the output dir to \\parentchild

            my @search_path; my @parent_search_path; #reinit arrays
			
            if ( $mameName ne '' ) 		{ foreach my $path ( 0 .. $#inputdir ) { push( @search_path, "$inputdir[$path]\\$mameName$fileType" ); } }
            if ( $mameParent ne '' )	{ foreach my $path ( 0 .. $#inputdir ) { push( @parent_search_path, "$inputdir[$path]\\$mameParent$fileType" ); } }
			
            $foundPath = ''; # first search for mame romname itself in the directories you specified
            until ($foundPath) {
                foreach my $path ( 0 .. $#search_path ) { #print "rom = $mameName, search path = $search_path[$path], path = $path\n" ;
                    if ( $search_path[$path] ne '' && -e $search_path[$path] ) {
                        $there++;
                        $foundPath = $search_path[$path];
                        printf HAVEFILE ( "%-15s %-15s %-25s %-15s", "$mameName", "Found", "Child is in path$path", " = $search_path[$path]\n" );
                        last;
                    }
                }

                if ( $foundPath eq '' && $opType ne 'Roms' ) { #if we're doing a non-rom operation, and if we didn't find the child in the above loop, search for its parent
                    foreach my $path ( 0 .. $#parent_search_path ) { #print "rom = $mameParent, search path = $parent_search_path[$path], path = $path\n" ;
                        if ( $parent_search_path[$path] ne '' && -e $parent_search_path[$path] ) {
                            $there++;
                            $foundPath = $parent_search_path[$path];
                            $outputdir = "$outputdir\\parentchild";
                            printf PARENTCHILDFILE ( "%-15s %-15s %-25s %-15s", "$mameName", "No child, but parent", "Parent is in path$path", " = $parent_search_path[$path]\n" );
                            last;
                        }
                    }
                }
            }

            if ( $foundPath eq '' ) { $notThere++; print "Can't find\t:\t$mameName\n"; print MISSFILE "Can't find\t=\t$mameName\n"; }
            #now do it - we hopefully never copy a parent rom as child name....
            if ($copy) { print COPYFILE "Copying $foundPath to $outputdir\\$mameName$fileType\n"; copy $foundPath, "$outputdir\\$mameName$fileType"; }
        }
    }

    printf "%-50s %10u", "\nnumber of mamenames present as child or parent:\t", ( defined $there ? "$there" : "0" );
    printf "%-46s %10u", "\nNumber of mamenames not found:\t", 					( defined $notThere ? "$notThere" : "0" );
}

sub CloseFileDirs {
    close(QPDATFILE);
    close(HAVEFILE);
    close(PARENTCHILDFILE);
    close(MISSFILE);
    close(COPYFILE);
}
