
OPTOOL="./optool"

IPA=$1
DYLIB_FOLDER=$2
TMPDIR=".patchapp.cache"

#
# Usage / syntax
#
function usage {
	if [ "$2" == "" -o "$1" == "" ]; then
		cat <<USAGE
Syntax: $0 <command> </path/to/your/ipa/file.ipa> [/path/to/your/file.mobileprovision]"
Where 'command' is one of:"
	info  - Show the information required to create a Provisioning Profile
	        that matches the specified .ipa file
	patch - Inject the current Theos tweak into the specified .ipa file.
	        Requires that you specify a .mobileprovision file.

USAGE
	fi
}

#
#
#

function copy_dylib_and_load {
	

	# copy the files into the .app folder
	echo '[+] Copying .dylib dependences into "'$TMPDIR/Payload/$APP'"'
	cp -rf $DYLIB_FOLDER $TMPDIR/Payload/$APP/Dylibs

	# re-sign Frameworks, too
	echo "APPDIR=$APPDIR"
	for file in `ls -1 $APPDIR/Dylibs`; do
		echo -n '     '
		echo "Install Load: $file -> @executable_path/Dylibs/$file"
		$OPTOOL install -c load -p "@executable_path/Dylibs/$file" -t $APPDIR/$APP_BINARY >& /dev/null
	done


	#--------

	if [ "$?" != "0" ]; then
		echo "Failed to inject "${DYLIB##*/}" into $APPDIR/${APP_BINARY}. Can I interest you in debugging the problem?"
		exit 1
	fi
	chmod +x "$APPDIR/$APP_BINARY"
}



#
# Setup all the things.
#
function setup_environment {
	if [ "$IPA" == "" ]; then
		usage
		exit 1
	fi
	if [ ! -r "$IPA" ]; then
		echo "$IPA not found or not readable"
		exit 1
	fi

	# setup
	rm -rf "$TMPDIR" >/dev/null 2>&1
	mkdir "$TMPDIR"
	SAVED_PATH=`pwd`

	# uncompress the IPA into tmpdir
	echo '[+] Unpacking the .ipa file ('"`pwd`/$IPA"')...'
	unzip -o -d "$TMPDIR" "$IPA" >/dev/null 2>&1
	if [ "$?" != "0" ]; then
		echo "Couldn't unzip the IPA file."
		exit 1
	fi

	cd "$TMPDIR"
	cd Payload/*.app
	if [ "$?" != "0" ]; then
		echo "Couldn't change into Payload folder. Wat."
		exit 1
	fi
	APP=`pwd`
	APP=${APP##*/}
	APPDIR=$TMPDIR/Payload/$APP
	cd "$SAVED_PATH"
	BUNDLE_ID=`plutil -convert xml1 -o - $APPDIR/Info.plist|grep -A1 CFBundleIdentifier|tail -n1|cut -f2 -d\>|cut -f1 -d\<`-patched
	APP_BINARY=`plutil -convert xml1 -o - $APPDIR/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`

}


#
# Zip folder back into Ipa
#
function repack_ipa {
	echo '[+] Repacking the .ipa'
	rm -f "${IPA%*.ipa}-patched.ipa" >/dev/null 2>&1
	zip -9r "${IPA%*.ipa}-patched.ipa" Payload/ >/dev/null 2>&1
	if [ "$?" != "0" ]; then
		echo "Failed to compress the app into an .ipa file."
		exit 1
	fi
	IPA=${IPA#../*}
	mv "${IPA%*.ipa}-patched.ipa" ..
	echo "[+] Wrote \"${IPA%*.ipa}-patched.ipa\""
	echo "[+] Great success!"
}

#
# Inject the current Theos tweak into the specified .ipa file
#
function ipa_patch {

	setup_environment


	if [ ! -x "$OPTOOL" ]; then
		echo "You need to install optool from here: https://github.com/alexzielenski/optool"
		echo "Then update OPTOOL variable in '$0' to reflect the correct path to the optool binary."
		exit 1
	fi

	copy_dylib_and_load

	cd $TMPDIR
	
	repack_ipa

	cd - >/dev/null 2>&1
}


	
ipa_patch 	
# success!
exit 0

