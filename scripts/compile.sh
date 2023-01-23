#!/usr/bin/env bash

export TAR_OUTPUT_DIR
TAR_OUTPUT_DIR="$(realpath "$1")"

ARCH="$2"
RELEASE_TAG="$3"

PKG_NAME="${RELEASE_TAG/-v*/}"
PKG_VERSION="${RELEASE_TAG/*-v/}"

mkdir -p "${TAR_OUTPUT_DIR}"

echo "Compiling: ${PKG_NAME}:${PKG_VERSION}"

clone_termux_packages() {
	# clone termux-packages into container
	tmp_dir="$(mktemp -d -t termux-packages-XXXXXXXXXX)"
	git clone https://github.com/termux/termux-packages.git "$tmp_dir/termux-packages"

	cd "$tmp_dir/termux-packages" && git checkout haskell-9.2.5
	mv -f "$tmp_dir"/termux-packages/* /home/builder/termux-packages
}

if [ "${PKG_NAME}" = "ghc" ]; then
	clone_termux_packages

	cd /home/builder/termux-packages || exit
	mkdir -p ./packages/ghc-cross
	cp ./packages/ghc/*.patch ./packages/ghc-cross
	cp -r ./ghc/* ./packages/ghc-cross

	./build-package.sh -I -a "${ARCH}" ghc-cross

elif [ "$PKG_NAME" = "cabal-install" ]; then
	# Cabal is for x86_64 so build only once.
	[ "${ARCH}" != "aarch64" ] && {
		touch "${TAR_OUTPUT_DIR}/.placeholder"
		tar -cJf "${TAR_OUTPUT_DIR}/placeholder-archive.tar.gz" -C "${TAR_OUTPUT_DIR}" .placeholder
		exit 0
	}
	bash ./build_cabal.sh "${PKG_NAME}"
fi
