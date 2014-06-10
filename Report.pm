use strict;
use warnings;

sub Report {
	my ($MISSFILE, $HAVEFILE, $PARENTCHILDFILE, $foundpath, $mamename, $parent, $found_index) = @_; 
	#need a whole bunch of info for logging, not acceptable really.....
	my $there = 0;
	
	if ($foundpath eq '') { 
		$there; 
		print "Can't find\t:\t$mamename\n"; print $MISSFILE "Can't find\t=\t$mamename\n"; 
		}
	if ($foundpath ne '') {  
		if 		($parent == 0) {
				printf $HAVEFILE ( "%-15s %-25s %-15s", "$mamename", "Found Child in path $found_index", " = $foundpath\n" );
		}
		elsif 	($parent == 1) {
				printf $PARENTCHILDFILE ( "%-15s %-25s %-15s", "$mamename", "No child, but Parent is in path$found_index", " = $foundpath\n" );
		}
	}

	
	return ($there);
}

return 1;
