#!/usr/bin/env bash

export TAR_OUTPUT_DIR="$(realpath $1)"
ARCH="$2"

# clone termux-packages into container
tmp_dir="$(mktemp -d -t termux-packages-XXXXXXXXXX)"
git clone https://github.com/MrAdityaAlok/termux-packages.git "$tmp_dir/termux-packages"

cd "$tmp_dir/termux-packages" && git checkout ghc
mv -f "$tmp_dir"/termux-packages/* /home/builder/termux-packages
cd /home/builder/termux-packages

mkdir -p ./packages/ghc-cross/
cp ./packages/ghc/*.patch ./packages/ghc-cross/
cp ./build.sh ./packages/ghc-cross/

./build-package.sh -I -a "${ARCH}" ghc-cross
