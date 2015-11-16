# nko Korunic, InfoMAR, 2008
# https://dkorunic.net/sources/scripts/squid-black-kre.sh
# SquidGuard merge blacklists

# bail out on error
set -e

# variables
TARGET=/tmp/ufdbguard
TMPDIR=$TARGET/bl-final
UFDB_HOME=/usr/local/ufdbguard
BLACKLISTS=$UFDB_HOME/blacklists

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

if [ -d "$TARGET" ]; then
	rm -rf $TARGET
fi

mkdir $TARGET
cd "$TARGET"

# cleanup
rm -rf "$TMPDIR" *tgz *tar.gz
mkdir "$TMPDIR"

# shalla
#wget http://www.shallalist.de/Downloads/shallalist.tar.gz
wget http://192.168.0.5/blacklists/shallalist.tar.gz
tar -xzf shallalist.tar.gz
rm -f shallalist.tar.gz
cd BL
mv adv ads
mv spyware malware 
cd ..
add_bl BL "$TMPDIR"

# touloise
#wget ftp://ftp.univ-tlse1.fr/pub/reseau/cache/squidguard_contrib/blacklists.tar.gz
wget http://192.168.0.5/blacklists/blacklists.tar.gz
tar -xvf blacklists.tar.gz
rm -f blacklists.tar.gz

cd blacklists
rm ads
mv publicite ads
rm aggressive
mv agressif aggressive
rm drugs
mv drogue drugs
rm porn
mv adult porn
rm violence
rm mail
mv forums forum
mv gambling gamble
mv financial finance
mv radio radiotv
mv press news
mv remote-control remotecontrol
mv social_networks socialnet
mv shortener urlshortener
mv update updatesites
mv associations_religieuses religion
mv download downloads
rm -rf reaffected
rm -rf liste_blanche
rm -rf liste_bu
rm -rf tricheur
rm -rf arjel
mv dangerous_material dangermat
mv sexual_education sex_ed
mv strict_redirector strict_redir
mv strong_redirector strong_redir
cd ..

add_bl blacklists "$TMPDIR"

if [ -d "$TMPDIR" ]; then
	# ignore missing existing dir
	if [ -d "$BLACKLISTS" ]; then
		mv "$BLACKLISTS" "$BLACKLISTS.$$" 
	fi

	mv "$TMPDIR" "$BLACKLISTS" 
	rm -rf "$TARGET"

	if [ -d "$BLACKLISTS.$$" ]; then
		rm -rf "$BLACKLISTS.$$"
	fi

	ln -s $UFDB_HOME/blacklist_exceptions/alwaysallow/ $BLACKLISTS
	ln -s $UFDB_HOME/blacklist_exceptions/alwaysblock/ $BLACKLISTS

	chown -R ufdb:ufdb $BLACKLISTS
fi


