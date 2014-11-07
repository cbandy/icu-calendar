#!/bin/sh -e

if [ "$1" = "before_install" ]; then

	if [ "$ICU_VERSION" ] ; then
		ICU_DIR="$(pwd)/icu/build"
		LD_LIBRARY_PATH="$ICU_DIR/lib"

		curl -L "https://downloads.sourceforge.net/project/icu/ICU4C/$ICU_VERSION/icu4c-$(echo $ICU_VERSION | tr . _)-src.tgz" | tar xz
		mkdir "$ICU_DIR"
		cd icu/source
		./runConfigureICU Linux --disable-extras --disable-samples --disable-tests --prefix="$ICU_DIR"
		make --quiet
		make --quiet install

		export ICU_DIR
		export LD_LIBRARY_PATH

	elif [ "$WITH_DEV_PACKAGE" ] ; then
		sudo apt-get install libicu-dev
	else
		sudo apt-get install $(apt-cache --names-only search libicu | grep -o '^libicu[0-9]* ')
	fi

fi
