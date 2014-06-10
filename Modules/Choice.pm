use strict;
use warnings;

sub Choice {
	my $op;	
	CHOICE: while ( $op = <STDIN> ) {
				chomp($op);
				if ( ( uc($op) eq uc("1") ) || ( $op eq "" ) ) { last CHOICE; }
				else { print "\nYou typed:\t$op.\n\nTry again - type either \"1\" or press Return:\t\n\n"; }
			}
	return $op
}

return 1;