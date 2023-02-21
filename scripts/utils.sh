#!/bin/bash

set -e -u

clone_termux_packages() {
	# clone termux-packages into container
	git clone -b update-haskell --single-branch https://github.com/termux/termux-packages.git
}

download() {
	url="$1"
	destination="$2"
	checksum="$3"

	curl --fail --retry 20 --retry-connrefused --retry-delay 30 --location -o "${destination}" "${url}" || {
		echo "Failed to download '${url}'."
		exit 1
	}

	if [ "${checksum}" != "SKIP" ]; then
		actual_checksum=$(sha256sum "${destination}" | cut -f 1 -d ' ')
		if [ "${checksum}" != "${actual_checksum}" ]; then
			printf >&2 "Wrong checksum for %s:\nExpected: %s\nActual:   %s\n" \
				"${url}" "${checksum}" "${actual_checksum}"
			return 1
		fi
	fi
}

setup_cabal() {
	version=3.8.1.0
	sha256=c71a1a46fd42d235bb86be968660815c24950e5da2d1ff4640da025ab520424b
	tar_tmpfile="$(mktemp -t cabal-bootstrap.XXXXXX).tar.gz"

	download "https://downloads.haskell.org/~cabal/cabal-install-${version}/cabal-install-${version}-x86_64-linux-deb10.tar.xz" \
		"${tar_tmpfile}" \
		"${sha256}"

	tar -xf "${tar_tmpfile}" -C "${BINDIR}"

	cabal update
}

setup_ghc() {
	version=9.2.5
	tar_tmpfile="$(mktemp -t ghc.XXXXXX).tar.xz"

	download "https://downloads.haskell.org/~ghc/${version}/ghc-${version}-x86_64-deb10-linux.tar.xz" \
		"${tar_tmpfile}" \
		89f2df47d86a45593d6ba3fd3a44b627d100588cd59be257570dbe3f92b17c48

	local ghc_extract_dir && ghc_extract_dir="$(mktemp -d -t ghc.XXXXXX)"
	local ghc_install_dir="${ROOT}/ghc"

	tar -xf "${tar_tmpfile}" -C "${ghc_extract_dir}" --strip-components=1

	cd "${ghc_extract_dir}"
	./configure --prefix="${ghc_install_dir}"
	make install

	export PATH="${ghc_install_dir}/bin:${PATH}"
}
