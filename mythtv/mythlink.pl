#!/usr/bin/perl -w

    use English;
    use File::Basename;
    use File::Path;
    use MythTV;

    $dir = "/opt/mythtv";
    my $myth = new MythTV();

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
	my @file = readdir DIR;
	closedir DIR;

	foreach my $file (@file) {
   	    if ($file ne "." and $file ne "..") {
	 	$link = readlink("$dirname/$file");
		if ($link eq $path) {
#	             print "Found existing link for $path : $dirname/$file\n";
		    next show;
		}
            }
	}

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
