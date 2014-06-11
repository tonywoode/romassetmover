use strict;
use warnings;

sub CheckInputs{
	my($SEVEN_ZIP_PATH, $inputfile, $output_dir_root, @inputdir) = @_; #need the inputs you set above
	
	my @removedirs;
	my $invalid_input;
	$inputfile 				eq ''? die "Quiting - You didn't set an input file\n" : print "Input file set to:\n $inputfile\n\n";
	$output_dir_root 		eq ''? die "Quiting - You didn't set an output dir\n" : print "Output directory set to:\n $output_dir_root\n\n";
	if ( scalar @inputdir == 0 ) { die "Quiting - You didn't pass me any input directories\n"; }
	else { VALID: foreach my $index ( 0 .. $#inputdir ) { 
		print "Input directory $index set to $inputdir[$index]\n"; 
		if	(! -e "$inputdir[$index]" ) { $invalid_input = "$inputdir[$index]"; last VALID; }
		(my $index_removedir, @inputdir) = CheckForZips($SEVEN_ZIP_PATH, $output_dir_root, $index, @inputdir); 
		if (defined $index_removedir) { push (@removedirs, $index_removedir); }
		}
	}
	return (\@removedirs, \@inputdir, $invalid_input); #return references to the arrays, can't return two arrays
}
return 1;