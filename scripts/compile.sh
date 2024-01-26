#!/usr/bin/bash

set -e -u

TAR_OUTPUT_DIR="$(realpath "$1")"
ARCH="$2"
RELEASE_TAG="$3"

ROOT="$(pwd)"
BINDIR="${ROOT}/bin"

source ./utils.sh

export PATH="${BINDIR}:${PATH}"
mkdir -p "$TAR_OUTPUT_DIR"
mkdir -p "${BINDIR}"

build_cabal() {
	setup_ghc
	setup_cabal
	local version=3.10.1.0
	local srcurl="https://github.com/haskell/cabal/archive/Cabal-v${version}.tar.gz"
	local sha256=710f9b14ad2851cb6192666599c37eff23b578cf619a1040bdf0b3f2c44df8b5

	local tar_tmpfile && tar_tmpfile="$(mktemp -t cabal.XXXXXX)"
	download "${srcurl}" "${tar_tmpfile}" "${sha256}"

	local build_dir && build_dir="$(mktemp -d -t cabal-install.XXXXXX)"
	tar -xf "${tar_tmpfile}" -C "${build_dir}" --strip-components=1

	cd "${build_dir}"

  for patch in "${ROOT}"/cabal-install/*.patch; do 
	  patch -p1 <"$patch"
  done

	mkdir -p "${build_dir}/bin"
	cabal install cabal-install \
		--install-method=copy \
		--installdir="${build_dir}/bin" \
		--project-file=cabal.project.release \
		--enable-library-stripping \
		--enable-executable-stripping \
		--enable-split-sections \
		--enable-executable-static

	tar -cJf "${TAR_OUTPUT_DIR}/cabal-install-${version}.tar.xz" -C "${build_dir}"/bin .
}

build_iserv_proxy() {
	setup_ghc
	setup_cabal

	version=9.2.5

	cd "$ROOT"/iserv-proxy
	mkdir -p ./bin

	cabal install iserv-proxy --project-file=cabal.project \
		--install-method=copy \
		--installdir="$(realpath ./bin)" \
		-flibrary -fproxy --constraint="libiserv +network" \
		--enable-executable-stripping \
		--enable-executable-static

	tar -cvJf "${TAR_OUTPUT_DIR}/iserv-proxy-${version}.tar.xz" -C ./bin .
}

PKG_NAME="${RELEASE_TAG/-v*/}"
PKG_VERSION="${RELEASE_TAG/*-v/}"

echo "Compiling: $PKG_NAME:$PKG_VERSION"

if [ "$PKG_NAME" = "ghc" ]; then
	clone_termux_packages

	cd termux-packages
	mkdir -p ./packages/ghc-cross
	cp ./packages/ghc-libs/*.patch ./packages/ghc-cross
	cp -r ./ghc/* ./packages/ghc-cross

	./build-package.sh -I -a "$ARCH" ghc-cross

elif [ "$PKG_NAME" = "cabal-install" ]; then
	# Cabal is for x86_64 so build only once.
	if [ "$ARCH" != "aarch64" ]; then
		touch "${TAR_OUTPUT_DIR}/.placeholder"
		tar -cJf "${TAR_OUTPUT_DIR}/placeholder-archive.tar.gz" -C "${TAR_OUTPUT_DIR}" .placeholder
		exit 0
	fi
	build_cabal
elif [ "$PKG_NAME" = "iserv-proxy" ]; then
	# Cabal is for x86_64 so build only once.
	if [ "$ARCH" != "aarch64" ]; then
		touch "${TAR_OUTPUT_DIR}/.placeholder"
		tar -cJf "${TAR_OUTPUT_DIR}/placeholder-archive.tar.gz" -C "${TAR_OUTPUT_DIR}" .placeholder
		exit 0
	fi
	build_iserv_proxy
fi
