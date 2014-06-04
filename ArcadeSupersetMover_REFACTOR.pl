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

################# INPUT YOUR SEARCH DIRECTORIES HERE###########################
undef $ARGV[0]? $inputfile = $ARGV[0] : $inputfile = 'C:\Emulators\QUICKPLAY\qp\data\Arcade\FinalBurn Alpha\ROMDATA.dat'; #Input file is the first cmd arg or what's here
undef $ARGV[1]? $output_dir_root = $ARGV[1] : $output_dir_root = 'F:\\Arcade\\TRANSIT';  #output dir is the 2nd cmd arg or what's here

@inputdir = ( #yes you have to set these here - search dirs - no trailing \ please!!!!
    'F:\Arcade\TRANSIT\UNZIP\MAMESCREENIES',
    'F:\Arcade\SCREENSHOTS\FBA_nonMAME_screenshots',
    'F:\Sega Games\HazeMD\HazeMD\snap',
    'F:\Arcade\SCREENSHOTS\Winkawaks_NONMAME_screenshots',
);
#Main program
EchoInputs();
( $optype, $filetype ) = OpChoice();
( $copy ) = SimChoice();
OpenFileDirs();
( $dat_line ) = ParseQPFile($inputfile);
print "\nScanning...\n";
while ( $line = <INPUTDATFILE> ) {
	( $foundPath, $this_outputdir, $mameName, $parent, $foundPathIndex ) = scanLine($line, $dat_line); #run the sub to find each rom
	Report();
	if ($copy) { print "\nCopying...\n"; }
	Copy();
	}
CloseFileDirs();

#Subs
#------------------------------------------------------------------------
sub EchoInputs{
print "\n\n" . "*" x 30 . "\n\n Romdata Asset Matching Tool\n\n" . "*" x 30 . "\n\n";
$inputfile 				eq ''? die "Quiting - You didn't set an input file\n" : print "Input file set to:\n $inputfile\n\n";
$output_dir_root 		eq ''? die "Quiting - You didn't set an output dir\n" : print "Output directory set to:\n $output_dir_root\n\n";
if ( scalar @inputdir == 0 ) { die "Quiting - You didn't pass me any input directories\n"; }
else { foreach $index ( 0 .. $#inputdir ) { print "Input directory $index set to $inputdir[$index]\n"; } }
}

#--------------------------------------------------------------------------
sub OpChoice{    #What are we doing and what filetype does that mean we'll look for?
	my $optype; 	my $filetype;
	my %filetypes = (
	#####INPUT YOUR ASSET AND FILTYPES HERE######
        "Roms"    => ".zip",
        "Screens" => ".png",
        "Titles"  => ".png",
        "Icons"   => ".ico",
	);
	
	my @menu_array; foreach my $keys (keys %filetypes) { unshift @menu_array, $keys }; #push the keys into array for the menu
    
	print "\nWhat do you want to compare?\n";
    for ( my $index = 0 ; $index < $#menu_array + 1 ; $index++ ) { print "\n\t$index)$menu_array[$index]\n"; }
    my $menu_item = <STDIN>;
    if ( $menu_item =~ /^[\+]?[0-$#menu_array]*\.?[0-$#menu_array]*$/ && $menu_item !~ /^[\. ]*$/ ){    #if its a number, and a number from the menu...
        $optype = $menu_array[$menu_item]; print "\nYou chose $optype\t";      	  #we get our operation type...
		$filetype = $filetypes{$optype}; print "So I'm going to look for:\t$filetype\n\n";
	} 
    else { die "\nNo, that's not sensible. Try again with a choice that's in the menu\n"; }
    return $optype, $filetype;   #returns the operation we'll do and it's filetype
}

#---------------------------------------------------------------------------
sub SimChoice { #Give user choice of behaviour
	my $copy;
    print "Simulate by default (just hit return), or enter '1' now to COPY\t";
	CHOICE: while ( $copy = <STDIN> ) {
				chomp($copy);
				if ( ( uc($copy) eq uc("1") ) || ( $copy eq "" ) ) { last CHOICE; }
				else { print "\nYou typed:\t$copy.\n\nTry again - type either \"1\" or press Return:\t\n\n"; }
			}
	return $copy
}

#------------------------------------------------------------------------
sub OpenFileDirs {
	open( INPUTDATFILE, $inputfile ) or die "Cannot open input dat file\n";
	$havefile = "$output_dir_root\\Have$optype.txt"; open( HAVEFILE, ">$havefile" );
	$missfile = "$output_dir_root\\Miss$optype.txt"; open( MISSFILE, ">$missfile" );
    $parentchildfile = "$output_dir_root\\ParentChild$optype.txt"; open( PARENTCHILDFILE, ">$parentchildfile" );
	if ($copy) { $copyfile = "$output_dir_root\\Copy$optype.txt"; open( COPYFILE, ">$copyfile" ); }
}

#------------------------------------------------------------------------
sub ParseQPFile {
	my $inputfile = shift(@_);
    $line = <INPUTDATFILE>;
    chomp $line;
    die "Quickplay data file not valid\n" if ( not $line =~ /ROM DataFile Version : / );    # check QP Data file is valid
    my $QPS        = chr(172);          #Quickplay's separator is ¬
    my $qp_pattern = "([^$QPS]*)$QPS";  #...so a Quickplay romdata entry consists of this pattern...
    my $dat_line 	   = "$qp_pattern" x 19; 	 #...and a line of Quickplay romdata consits of that entry repeated 19 times
	return $dat_line
}

#------------------------------------------------------------------------
sub scanLine {
		my $line = shift(@_); my $dat_line = shift(@_);
        chomp $line;
        if ( $line =~ /^$dat_line/ ) {
            my $mameName   = $2;    #mamename
            my $mameParent = $3;    #parent romname
			
			$foundPathIndex = -1;
			my $parent = 0;			
            my $foundPath = ''; # first search for mame romname itself in the directories you specified
			
			until ($foundPath) {
                foreach my $path ( 0 .. $#inputdir ) { #print "rom = $mameName, search path = $search_path[$path], path = $path\n" ;
                    if    ( $mameName ne '' && -e "$inputdir[$path]\\$mameName$filetype" ) { $foundPath = "$inputdir[$path]\\$mameName$filetype"; $foundPathIndex = $path; }
					elsif ( $mameParent ne '' && -e "$inputdir[$path]\\$mameParent$filetype" && $optype ne 'Roms' ) { $parent = 1; $foundPath = "$inputdir[$path]\\$mameParent$filetype"; $foundPathIndex = $path; }
                    else { break; }
                }
			}
		return $foundPath, $this_outputdir, $mameName, $parent, $foundPathIndex;
		}
	}

#------------------------------------------------------------------------
sub Report {
		if ( $foundPath eq '' ) { $notThere++; print "Can't find\t:\t$mameName\n"; print MISSFILE "Can't find\t=\t$mameName\n"; }
		if ( $foundPath ne '' ) { 
			$there++; 
			if ( $parent == 0 ) {printf HAVEFILE ( "%-15s %-15s %-25s %-15s", "$mameName", "Found", "Child is in path $foundPathIndex", " = $foundPath\n" );}
			elsif ( $parent == 1 ) { printf PARENTCHILDFILE ( "%-15s %-15s %-25s %-15s", "$mameName", "No child, but parent", "Parent is in path$foundPathIndex", " = $foundPath\n" );}
		
		}
		printf "%-50s %10u", "\nnumber of mamenames present as child or parent:\t", ( defined $there ? 	  "$there" : "0" );
		printf "%-46s %10u", "\nnumber of mamenames not found:\t", 					( defined $notThere ? "$notThere" : "0" );
}
		
#-------------------------------------------------------------------------
sub Copy {	
		if ($copy) { #now do it - we hopefully never copy a parent rom as child name....
			$this_outputdir = "$output_dir_root\\$optype"; make_path $this_outputdir;
			if ( $parent == 1 ) { $this_outputdir .= "\\parentchild"; } make_path $this_outputdir;
			my $outputFile = "$this_outputdir\\$mameName$filetype";
			print COPYFILE "Copying $foundPath to $outputFile\n"; copy $foundPath, $outputFile; 
		}
}

#-------------------------------------------------------------------------
sub CloseFileDirs {
    close(INPUTDATFILE);
    close(HAVEFILE);
    close(PARENTCHILDFILE);
    close(MISSFILE);
    close(COPYFILE);
}
