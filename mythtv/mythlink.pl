#!/usr/bin/perl -w

use File::stat;
use English;
use File::Basename;
use File::Path;
use File::Find;
use MythTV;

$dir = "/opt/mythtv";
my $myth = new MythTV();
$now = time;

my %rows = $myth->backend_rows('QUERY_RECORDINGS Descending');

show: foreach my $row (@{$rows{'rows'}}) {
    my $show = $myth->new_recording(@$row);
	my $title = $show->{'title'};
	my $subtitle = $show->{'subtitle'};
	my $path = $show->{'local_path'};

	my $dirname = "$dir/$title";
	unless (-e $dirname) {
	   	mkpath($dirname, 0, 0775) or die "Failed to create $dirname:  $!\n";
	}

	opendir DIR, $dirname or die "cannot open dir $dirname: $!";
	my @files = grep { !/^\.{1,2}$/ } readdir (DIR);
	closedir DIR;

	@files = map { $dirname . '/' . $_ } @files;
	foreach my $file (@files) {
	 	$link = readlink($file);
		if ($link eq $path) {
			# touch existing mtime for soft link, so its not deleted later
			system("touch -h \"$file\"");
			# found existing link, so skip to next show
		    next show;
		}
	}

	# ok so we have a show which does not yet have a link, so lets create one
    my ($suffix) = ($show->{'basename'} =~ /(\.\w+)$/);

    $name = $subtitle;
	# Check for duplicates
    if (-e "$dirname/$name$suffix") {
        $count = 2;
        while (-e "$dirname/$name.$count$suffix") {
            $count++;
        }
        $name .= ".$count";
    }
    $name .= $suffix;

	print "New link required for $name\n";

	symlink $show->{'local_path'}, "$dirname/$name"
       or die "Can't create symlink $dirname/$name:  $!\n";
}

# now lets go and cleanup all symlinks which are dead, or were not touched
find(\&cleanup_old_links, ".");

sub cleanup_old_links {
	my $file = $_;

	if (-l $file) {
		$sb = lstat($file);
		if ($sb->mtime < $now) {
			unlink $file
				or die "Can't delete symlink $file: $!\n";
		}
	}
}

