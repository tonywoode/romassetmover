use strict;
use warnings;

package ArcadeTools::Shared;

use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Find;
use List::MoreUtils qw(uniq);

use base 'Exporter';
our @EXPORT_OK = ('CheckInputs','RemoveTempDirs','OpChoice','Choice','ParseQPFile', 'SearchUniqInB','ScanLine','Copy','Report');

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

sub Choice {
	my $op;	
	CHOICE: while ( $op = <STDIN> ) {
				chomp($op);
				if ( ( uc($op) eq uc("1") ) || ( $op eq "" ) ) { last CHOICE; }
				else { print "\nYou typed:\t$op.\n\nTry again - type either \"1\" or press Return:\t\n\n"; }
			}
	return $op
}

sub CheckInputs{
	my($SEVEN_ZIP_PATH, $inputfile, $output_dir_root, @inputdirs) = @_; #need the inputs you set above
	
	my @removedirs;
	my $invalid_input;
	$inputfile 				eq ''? die "Quiting - You didn't set an input file\n" : print "Input file set to:\n $inputfile\n\n";
	$output_dir_root 		eq ''? die "Quiting - You didn't set an output dir\n" : print "Output directory set to:\n $output_dir_root\n\n";
	if ( scalar @inputdirs == 0 ) { die "Quiting - You didn't pass me any input directories\n"; }
	else { VALID: foreach my $index ( 0 .. $#inputdirs ) { 
		print "Input directory $index set to $inputdirs[$index]\n"; 
		if	(! -e "$inputdirs[$index]" ) { $invalid_input = "$inputdirs[$index]"; last VALID; }
		(my $index_removedir, @inputdirs) = CheckForZips($SEVEN_ZIP_PATH, $output_dir_root, $index, @inputdirs); 
		if (defined $index_removedir) { push (@removedirs, $index_removedir); }
		}
	}
	return (\@removedirs, \@inputdirs, $invalid_input); #return references to the arrays, can't return two arrays
}

sub CheckForZips {
	my ($SEVEN_ZIP_PATH, $output_dir_root, $index, @inputdirs) = @_;
	my $index_removedir;
	
	my ($name, $path, $ext) = ( fileparse($inputdirs[$index], qr/\.[^.]*/) );
	#print "ext is\t$ext\n"; #print "name is\t$name\n"; #print "path is\t$path\n";
	$ext = lc("$ext");
	if ($ext eq '.zip' || $ext eq '.7z') { 
		($index_removedir, @inputdirs) = UnZip($SEVEN_ZIP_PATH, $output_dir_root, $index, $name, @inputdirs); 
	}
	return ($index_removedir, @inputdirs)#pass up the details of any replaced indexes so we can delete the dir later....
}

sub UnZip { #Uncompress zip archive at this array index, REPLACE the array index with the new loaction, flag theres a folder to delete at the end
	my ($SEVEN_ZIP_PATH, $output_dir_root, $index, $name, @inputdirs) = @_; 
	
	my $unzip_dir = "$output_dir_root\\deleteme\\$name\\$index";
	print "\t$inputdirs[$index] is an archive file\n\tMade temp dir at $unzip_dir\nUnzipping...";
	
	my $output = `\"$SEVEN_ZIP_PATH\" -y e \"$inputdirs[$index]\" -o\"$unzip_dir\"`;		#https://uk.answers.yahoo.com/question/index?qid=20130128061122AAIubF5
																#note the -o must touch the output dir. its a 7zip thing not perl.  -y assumes yes to all promps
	if ($output =~ /Everything is Ok/g){ print "\nUnzip Complete - All OK\n"; }
	else{ die "\nSomething went wrong with the Unzip, exiting (try unzipping it yourself)\n"; } 
	
	$inputdirs[$index]= $unzip_dir;			#now we have the zip, we have to change the array
	
	my $index_removedir = $index; 			#we'll remove the folder at this location when we're done
	return ($index_removedir, @inputdirs); 	#...so return that index and the new dir
}

sub ParseQPFile {
	my ($INPUTDATFILE) = @_;
	
    my $line = <$INPUTDATFILE>; chomp $line;
    die "Quickplay data file not valid\n" if ( not $line =~ /ROM DataFile Version : / );
    my $QPS        = chr(172);          		#Quickplay's separator is ¬
    my $qp_pattern = "([^$QPS]*)$QPS";  		#...so a Quickplay romdata entry consists of this pattern
    my $dat_line 	   = "$qp_pattern" x 19; 	#...and a line of Quickplay romdata consits of that entry repeated 19 times
	return $dat_line;
}

sub ScanLine {#need a line of romdata, a line format, a directory the files are in and their type, and the operation
	my($line, $dat_line, $filetype, @inputdirs ) = @_;
	
    chomp $line;
    if ( $line =~ /^$dat_line/ ) {
		my $mamename   = $2;    #the name of the mame asset we're looking for is the 3rd field
        my $mameparent = $3;    #that rom's parent is the 4th		
		
		my $found_index = -1;
		my $parent = 0;			
        my $foundpath = '';
		
		print "\nScanning...\n";
			
		MAMESEARCH:until ($foundpath) {
              foreach my $path (0 .. $#inputdirs) {	  
                    if		( $mamename ne '' && -e "$inputdirs[$path]\\$mamename$filetype" ) { 
							$foundpath = "$inputdirs[$path]\\$mamename$filetype"; 
							$found_index = $path; 
							last MAMESEARCH;
					}
					elsif	( $mameparent ne '' && -e "$inputdirs[$path]\\$mameparent$filetype" ){
							$parent = 1; 
							$foundpath = "$inputdirs[$path]\\$mameparent$filetype"; 
							$found_index = $path; 
							last MAMESEARCH;
					}   
              } 
		last MAMESEARCH; #$foundpath will be ''
		} 
	return $foundpath, $mamename, $parent, $found_index; #give back the path, and some less important stuff for reporting
	}
}

sub SearchUniqInB{ #finds files in the second directory in the array that are not in the first, only finds files with the file extension specified
	my ($filetype, $HAVEFILE, $MISSFILE, @inputdirs) = @_;
	#we scan for the roms in the input, report what we found, and copy if appropriate
	my (%files1, %files2);
	find(sub { if ($File::Find::name =~ /$filetype$/ && -f ) { $files1{$_} = $File::Find::name; } }, $inputdirs[0]); #wanted-> construct put fullpath in value AND key?!?
	find(sub { if ($File::Find::name =~ /$filetype$/ && -f ) { $files2{$_} = $File::Find::name; } }, $inputdirs[1]);

	my @all = uniq(keys %files1, keys %files2);
	my %uniq_in_target;
	
	for my $file (@all) {
		if ($files1{$file} && $files2{$file} && $file ne '.') { #file exists in both dirs
			print $HAVEFILE "$file is in both dirs\n";
		}
		elsif ($files1{$file}) { #file is only in dir 1
			print $HAVEFILE "$file is in $inputdirs[0] and not in $inputdirs[1]\n";
		}
		else { #file is only in dir 2
			print $MISSFILE "$file is in $inputdirs[1] and not in $inputdirs[0]\n";
			$uniq_in_target{$file} = $files2{$file};
		}
	}
	return %uniq_in_target;
}

sub Report {
	my ($MISSFILE, $HAVEFILE, $PARENTCHILDFILE, $foundpath, $mamename, $parent, $found_index) = @_; 
	#need a whole bunch of info for logging, not acceptable really.....
	my $present = 0;
	
	if ($foundpath eq '') {print "Can't find\t:\t$mamename\n"; print $MISSFILE "Can't find\t=\t$mamename\n";}
	if ($foundpath ne '') { 
		$present = 1; 
		if    ($parent == 0) { printf $HAVEFILE ( "%-15s %-25s %-15s", "$mamename", "Found Child in path $found_index", " = $foundpath\n" );}
		elsif ($parent == 1) { printf $PARENTCHILDFILE ( "%-15s %-25s %-15s", "$mamename", "No child, but Parent is in path$found_index", " = $foundpath\n" );}
	}
	
	return ($present);
}

sub Copy {
	my ($COPYFILE, $output_dir_root, $optype, $parent, $foundpath, $mamename, $filetype) = @_; 
	#need the file to report to, the output dir, the type of operation (for folder name), whether we're copying a parent asset,
	#	the path to use for this copy, the mamename to copy to, and the operation's filetype. With this info we can do many types of copy....
	
	my $this_outputdir = "$output_dir_root\\$optype"; make_path $this_outputdir;
	if ($parent == 1) { $this_outputdir .= "\\parentchild"; } make_path $this_outputdir;
		my $outputfile = "$this_outputdir\\$mamename$filetype";
		print "\nCopying...\n";
		print $COPYFILE "Copying $foundpath to $outputfile\n"; copy $foundpath, $outputfile; 
}

sub RemoveTempDirs {
	my ($output_dir_root, $removedirs_ref, $inputdirs_ref) = @_; #taking in two array references
	my @removedirs = @$removedirs_ref; my @inputdirs = @$inputdirs_ref; #dereferencing them
	foreach my $index (0 .. $#removedirs) {
		my $index_of_path = $removedirs[$index];
		print "\nOk to remove temp dir?: $inputdirs[$index_of_path]\n1 for yes\t";
		my ($delete) = Choice();
		if ($delete) { remove_tree($inputdirs[$index_of_path]); }
	}
	if ( -e "$output_dir_root\\deleteme") { remove_tree "$output_dir_root\\deleteme" } #we made a dir to keep the temps in, delete it at the end...
}
1;