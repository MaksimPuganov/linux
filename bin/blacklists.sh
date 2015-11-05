# nko Korunic, InfoMAR, 2008
# https://dkorunic.net/sources/scripts/squid-black-kre.sh
# SquidGuard merge blacklists

# bail out on error
set -e

# variables
TARGET=/usr/local/ufdbguard
TMPDIR=bl-final
SADIR=$TARGET/blacklists
LOCKFILE=/var/lock/ufdbguard-black-gen.lock

# merge lists
merge_bl() {
	SRC="$1"
	DST="$2"

	# sanity checking
	if [ -z "$SRC" -o -z "$DST" ]; then
		return
	fi

	if [ ! -r "$SRC" ]; then
		return
	fi

	cat "$SRC" >> "$DST"

	sort -u "$DST" | grep -v '^#' > "$DST.$$" && \
		mv -f "$DST.$$" "$DST"
	rm -f "$DST.$$"
}

# iterate lists, sort and merge if possible
add_bl() {
	SRCDIR="$1"
	DSTDIR="$2"

	# sanity checking
	if [ -z "$SRCDIR" -o -z "$DSTDIR" ]; then
		return
	fi
	if [ ! -d "$SRCDIR" ]; then
		return
	fi

	# possible that it is empty
	mkdir -p "$DSTDIR"

	# iterate the merge procedure
	DIRS=$(find "$SRCDIR" \( -type d -o -type l \))
	for dir in $DIRS; do
		# extract first-level name
		short=$(echo "$dir" | cut -d/ -f2)
		for file in domains urls; do
			if [ -e "$dir/$file" ]; then
				mkdir -p "$DSTDIR/$short"
				merge_bl "$dir/$file" "$DSTDIR/$short/$file"
			fi
		done
	done

	rm -rf "$SRCDIR"
}

cd "$TARGET"

if [ $# -eq 0 ]; then
	# cleanup
	rm -rf "$TMPDIR" *tgz *tar.gz
	mkdir "$TMPDIR"

	# mesd
	wget http://squidguard.mesd.k12.or.us/blacklists.tgz
	tar -xvf blacklists.tgz
	rm -f blacklists.tgz
	add_bl blacklists "$TMPDIR"

	# shalla
	wget http://www.shallalist.de/Downloads/shallalist.tar.gz
	tar -xzf shallalist.tar.gz
	rm -f shallalist.tar.gz
	add_bl BL "$TMPDIR"

	# touloise
	wget ftp://ftp.univ-tlse1.fr/pub/reseau/cache/squidguard_contrib/blacklists.tar.gz
	tar -xvf blacklists.tar.gz
	rm -f blacklists.tar.gz
	add_bl blacklists "$TMPDIR"
fi

if [ -d "$TARGET/$TMPDIR" ]; then
	# ignore missing existing dir
	if [ -d "$SADIR" ]; then
		mv "$SADIR" "$SADIR.$$" 
	fi

	mv "$TARGET/$TMPDIR" "$SADIR" 
	rm -rf "$TARGET/$TMPDIR"

	if [ -d "$SADIR.$$" ]; then
		rm -rf "$SADIR.$$"
	fi

	mv $SADIR/dangerous_material/ $SADIR/dangermat
	mv $SADIR/sexual_education/ $SADIR/sex_ed
	mv $SADIR/strict_redirector/ $SADIR/strict_redir
	mv $SADIR/strong_redirector/ $SADIR/strong_redir

	ln -s $TARGET/blacklist_exceptions/alwaysallow/ $SADIR
	ln -s $TARGET/blacklist_exceptions/alwaysblock/ $SADIR

	chown -R ufdb:ufdb $SADIR
fi


find $SADIR -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | while read table; do
    [ -f $SADIR/${table}/domains ] || continue

    myparams="-W -t $table -d $SADIR/${table}/domains"
    [ -f $SADIR/urls ] && myparams="${myparams} -u $SADIR/${table}/urls"

    $TARGET/bin/ufdbGenTable ${myparams} || exit=1
done
 
sudo $TARGET/bin/ufdbConvertDB -d $SADIR

sudo /usr/local/bin/restartproxy

exit $exit

