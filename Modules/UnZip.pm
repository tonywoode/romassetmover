use strict;
use warnings;

sub UnZip { #Uncompress zip archive at this array index, REPLACE the array index with the new loaction, flag theres a folder to delete at the end
	my ($SEVEN_ZIP_PATH, $output_dir_root, $index, $name, @inputdir) = @_; 
	
	my $unzip_dir = "$output_dir_root\\deleteme\\$name";
	print "\t$inputdir[$index] is an archive file\n\tMade temp dir at $unzip_dir\nUnzipping...";
	
	my $output = `\"$SEVEN_ZIP_PATH\" -y e \"$inputdir[$index]\" -o\"$unzip_dir\"`;		#https://uk.answers.yahoo.com/question/index?qid=20130128061122AAIubF5
																#note the -o must touch the output dir. its a 7zip thing not perl.  -y assumes yes to all promps
	if ($output =~ /Everything is Ok/g){ print "\nUnzip Complete - All OK\n"; }
	else{ die "\nSomething went wrong with the Unzip, exiting (try unzipping it yourself)\n"; } 
	
	$inputdir[$index]= $unzip_dir;			#now we have the zip, we have to change the array
	
	my $index_removedir = $index; 			#we'll remove the folder at this location when we're done
	return ($index_removedir, @inputdir); 	#...so return that index and the new dir
}
return 1;