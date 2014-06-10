use strict;
use warnings;

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

return 1;