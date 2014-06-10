use strict;
use warnings;

require MOdules::UnZip;

sub CheckForZips {
	my ($SEVEN_ZIP_PATH, $output_dir_root, $index, @inputdir) = @_;
	my $index_removedir;
	
	my ($name, $path, $ext) = ( fileparse($inputdir[$index], qr/\.[^.]*/) );
	#print "ext is\t$ext\n"; #print "name is\t$name\n"; #print "path is\t$path\n";
	$ext = lc("$ext");
	if ($ext eq '.zip' || $ext eq '.7z') { 
		($index_removedir, @inputdir) = UnZip($SEVEN_ZIP_PATH, $output_dir_root, $index, $name, @inputdir); 
	}
	return ($index_removedir, @inputdir)#pass up the details of any replaced indexes so we can delete the dir later....
}
return 1;
