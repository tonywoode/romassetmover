use strict;
use warnings;

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
return 1;