#!/bin/bash

set -e -u

VERSION=3.6.2.0
SRCURL="https://github.com/haskell/cabal/archive/Cabal-v${VERSION}.tar.gz"
SHA256=dcf31e82cd85ea3236be18cc36c68058948994579ea7de18f99175821dbbcb64

download() {
	url="$1"
	destination="$2"
	checksum="$3"

	curl --fail --retry 20 --retry-connrefused --retry-delay 30 --location -o "${destination}" "${url}" || {
		echo "Failed to download '${url}'."
		exit 1
	}

	actual_checksum=$(sha256sum "${destination}" | cut -f 1 -d ' ')
	if [ "${checksum}" != "${actual_checksum}" ]; then
		printf >&2 "Wrong checksum for %s:\nExpected: %s\nActual:   %s\n" \
			"${url}" "${checksum}" "${actual_checksum}"
		return 1
	fi
}

setup_boot_cabal() {
	version=3.6.0.0
	sha256="bfcb7350966dafe95051b5fc9fcb989c5708ab9e78191e71fc04647061668a11"
	tar_tmpfile="$(mktemp -t cabal-bootstrap.XXXXXX).tar.gz"

	download "https://downloads.haskell.org/~cabal/cabal-install-${version}/cabal-install-${version}-x86_64-linux.tar.xz" \
		"${tar_tmpfile}" \
		"${sha256}"

	mkdir -p boot-cabal
	tar -xf "${tar_tmpfile}" -C boot-cabal
	export PATH="$(realpath ./boot-cabal):${PATH}"

	cabal update
}

setup_ghc() {
	version="8.10.7"
	tar_tmpfile="$(mktemp -t ghc.XXXXXX).tar.xz"

	download "https://downloads.haskell.org/~ghc/${version}/ghc-${version}-x86_64-deb10-linux.tar.xz" \
		"${tar_tmpfile}" \
		a13719bca87a0d3ac0c7d4157a4e60887009a7f1a8dbe95c4759ec413e086d30

	mkdir -p ghc/prefix
	tar -xf "${tar_tmpfile}" -C ghc --strip-components=1
	cd ghc && ./configure --prefix="$(pwd)/prefix" && make install

	export PATH="$(pwd)/prefix/bin:${PATH}"
}

build_cabal() {
	tar_tmpfile="$(mktemp -t cabal.XXXXXX).tar.xz"
	download "${SRCURL}" "${tar_tmpfile}" "${SHA256}"

	mkdir -p build && cd build
	tar -xf "${tar_tmpfile}" --strip-components=1

	patch -p1 <./correct-host-triplet.patch

	mkdir -p bin
	cabal install cabal-install \
		--install-method=copy \
		--installdir="$(pwd)/bin" \
		-O \
		--project-file=cabal.project.release \
		--enable-library-stripping \
		--enable-executable-stripping \
		--enable-split-sections \
		--enable-executable-static

	tar -cJf "${TAR_OUTPUT_DIR}/cabal-install-${VERSION}.tar.xz" -C bin .

}
setup_boot_cabal
setup_ghc

build_cabal
