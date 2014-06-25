#"C:\Perl64\bin\perl.exe" -w
#
# This is intented to move all the files in the filepath field of a QP romdata to a common directory. To UN-LoqiqX a set of arcade roms
# It does NOT look inside zips, meaning it just moves bare romnames. You'll have to RomCentre the result against an arcade set dat to get
# A working set.
# We open a romdata.dat, on each line find the path field, and copy that field to a common directory, using the name ROMS
#
#use diagnostics;
use strict;
use warnings;
use File::Path qw(make_path);
use File::Copy qw(copy);

#the subs we share
use ArcadeTools::Shared ('CheckInputs','RemoveTempDirs','OpChoice','ParseQPFile','Choice','SearchUniqInB','Copy','Report');

my ($inputfile, $output_dir_root);
##### INPUT YOUR SEARCH DIRECTORIES HERE #####
undef $ARGV[0]? $inputfile = $ARGV[0] 		: $inputfile = do 'Inputdatfile.txt'; #Input file = first cmd arg, else what's in that txt file...
undef $ARGV[1]? $output_dir_root = $ARGV[1] : $output_dir_root = do 'Outputdir.txt';  #output dir is the 2nd cmd arg or what's in that txt file...

$inputfile 				eq ''? die "Quiting - You didn't set an input file\n" : print "Input file set to:\n $inputfile\n\n";
$output_dir_root 		eq ''? die "Quiting - You didn't set an output dir\n" : print "Output directory set to:\n $output_dir_root\n\n";

my $optype = "Roms";
my $filetype = ".zip";
my $this_outputdir = "$output_dir_root\\$optype"; make_path $this_outputdir;

#are we copying or not?
print "Simulate by default (just hit return), or enter '1' now to COPY\t";
my ($copy ) 			= Choice();	

#we name the output files and folders by operation type
my ($INPUTDATFILE, $HAVEFILE, $MISSFILE, $COPYFILE) = OpenFileDirs($output_dir_root, $optype);

#we learn what a QP datafile looks like
my ($dat_line) 			= ParseQPFile($INPUTDATFILE);

#we scan for the roms in the input, report what we found, and copy if appropriate
my ($there, $notthere); #need to init before the report loop, present is a boolean passed to the sub from which we keep count
while (my $line = <$INPUTDATFILE> ) {					
	chomp $line;
	my $outputfile;
	if ( $line =~ /^$dat_line/ ) {
		my $mamename   = $2;    #the name of the mame asset we're looking for is the 3rd field		
        my $foundpath = $5;
		print "\nScanning...\n";
		if ( $mamename ne '' && -e $foundpath ) { 
			$outputfile = "$this_outputdir\\$mamename$filetype";
			print $HAVEFILE "can copy $mamename from $foundpath to $outputfile\n";
			if ($copy) { 
				copy $foundpath, $outputfile; 
				print $COPYFILE "Copying $mamename from $foundpath to $outputfile\n";
				$there++;
			}  
			printf "%-50s %10u", "\nnumber of mamenames copied:\t", ( defined $there ? 	  "$there" : "0" );
		}
		else {
			print $MISSFILE "Error copying $mamename from $foundpath\n";
			$notthere++;
		printf "%-46s %10u", "\nnumber of mamenames not copied:\t", ( defined $notthere ? "$notthere" : "0" );
		}
	}
}

CloseFileDirs();
print "\nFinished\n";


















#LOCAL SUBS--------------------------------------------------------------------
sub OpenFileDirs {
	my ($output_dir_root, $optype) = @_; # need to know the root output dir, the type of asset to name folders, and whether we are copying
	
	open(my $INPUTDATFILE, "<", $inputfile) || die "Couldn't open '".$inputfile."' for reading because: ".$!;
	
	#boiler plate opening of the four filetypes
	my $havefile = "$output_dir_root\\Have$optype.txt"; open(my $HAVEFILE, ">", $havefile) || die "Couldn't open '".$havefile."' for reading because: ".$!;
	my $missfile = "$output_dir_root\\Miss$optype.txt"; open(my $MISSFILE, ">", $missfile) || die "Couldn't open '".$missfile."' for reading because: ".$!;
    my $copyfile = "$output_dir_root\\Copy$optype.txt";	open(my $COPYFILE, ">", $copyfile) || die "Couldn't open '".$copyfile."' for reading because: ".$!;
	
	return ($INPUTDATFILE, $HAVEFILE, $MISSFILE, $COPYFILE);
}
	
sub CloseFileDirs {
    close($INPUTDATFILE);
    close($HAVEFILE);
    close($MISSFILE);
    close($COPYFILE);
}
	
	