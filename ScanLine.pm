use strict;
use warnings;

sub ScanLine {#need a line of romdata, a line format, a directory the files are in and their type, and the operation
	my($line, $dat_line, $filetype, @inputdir ) = @_;
	
    chomp $line;
    if ( $line =~ /^$dat_line/ ) {
		my $mamename   = $2;    #the name of the mame asset we're looking for is the 3rd field
        my $mameparent = $3;    #that rom's parent is the 4th		
		
		my $found_index = -1;
		my $parent = 0;			
        my $foundpath = '';
		
		print "\nScanning...\n";
			
		MAMESEARCH:until ($foundpath) {
              foreach my $path (0 .. $#inputdir) {	  
                    if		( $mamename ne '' && -e "$inputdir[$path]\\$mamename$filetype" ) { 
							$foundpath = "$inputdir[$path]\\$mamename$filetype"; 
							$found_index = $path; 
							last MAMESEARCH;
					}
					elsif	( $mameparent ne '' && -e "$inputdir[$path]\\$mameparent$filetype" ){
							$parent = 1; 
							$foundpath = "$inputdir[$path]\\$mameparent$filetype"; 
							$found_index = $path; 
							last MAMESEARCH;
					}   
              } 
		last MAMESEARCH; #$foundpath will be ''
		} 
	return $foundpath, $mamename, $parent, $found_index; #give back the path, and some less important stuff for reporting
	}
}
return 1;