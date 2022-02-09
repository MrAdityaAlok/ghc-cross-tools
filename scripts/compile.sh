#!/usr/bin/env bash

export TAR_OUTPUT_DIR="$(realpath $1)"
ARCH="$2"
WHAT_TO_COMPILE="$3"

mkdir -p "${TAR_OUTPUT_DIR}"

echo "Compiling: ${WHAT_TO_COMPILE}"

clone_termux_packages() {
	# clone termux-packages into container
	tmp_dir="$(mktemp -d -t termux-packages-XXXXXXXXXX)"
	git clone https://github.com/MrAdityaAlok/termux-packages.git "$tmp_dir/termux-packages"

	cd "$tmp_dir/termux-packages" && git checkout ghc # TODO: remove after ghc is merged
	mv -f "$tmp_dir"/termux-packages/* /home/builder/termux-packages
	cd /home/builder/termux-packages
}

if [ "${WHAT_TO_COMPILE}" = "ghc" ]; then
	clone_termux_packages

	mkdir -p ./packages/ghc-cross
	cp ./packages/ghc/*.patch ./packages/ghc-cross
	cp ./ghc/build.sh ./packages/ghc-cross

	./build-package.sh -I -a "${ARCH}" ghc-cross

else
	# Only build ones
	[ "${ARCH}" != "aarch64" ] && {
		touch "${TAR_OUTPUT_DIR}/.placeholder"
		tar -cJf "${TAR_OUTPUT_DIR}/placeholder-archive.tar.xz" -C "${TAR_OUTPUT_DIR}" .placeholder
		exit 0
	}
	bash ./cabal-install/build.sh "${WHAT_TO_COMPILE}"
fi
