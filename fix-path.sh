#!/usr/bin/env bash

# This script is used to replace the default PREFIX of ghc packages with $NEW_PREFIX.

# The MIT License (MIT)

# Copyright (c) 2022 Aditya Alok @MrAdityaAlok <dev.aditya.alok+legal@gmail.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

usage() {
	echo "Fix PREFIX of ghc packages."
	echo "Usage: $(basename "$0") <path to directory where GHC has been unpacked/installed>"
}

if [ -z "$1" ] || [ "$#" -gt 1 ]; then
	usage
	exit 1
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
	usage
	exit 0
elif [ ! -d "$1" ]; then
	echo "Directory $1 does not exist."
	exit 1
fi

GHC_ROOT="$(realpath $1)"

CURRENT_PREFIX="$(cat "${GHC_ROOT}"/bin/*-ghc | grep "bindir" | sed 's/bindir="//g' | sed 's/\/bin"//g')"
NEW_PREFIX="${GHC_ROOT}"
echo "Info: Current PREFIX $CURRENT_PREFIX"
[ "${CURRENT_PREFIX}" = "${NEW_PREFIX}" ] && echo "PREFIX already set to ${NEW_PREFIX}" && exit 0
echo "Info: New PREFIX $NEW_PREFIX"

replace_path() {
	local file="$(realpath $1)" # Realpath to resolve symlinks
	[ -f "$file" ] || {
		echo "Warning: Skipping $file. Not a file." >&2
		return
	}
	sed -i "s|${CURRENT_PREFIX}|${NEW_PREFIX}|g" "${file}"
}

for file in "${GHC_ROOT}"/bin/*; do
	replace_path "${file}"
done

for file in "${GHC_ROOT}"/lib/*/package.conf.d/*.conf; do
	replace_path "${file}"
done

printf "%s" "Recaching ghc packages..."
"${GHC_ROOT}"/bin/*-ghc-pkg recache >/dev/null || {
	echo "Failed to recache ghc packages." >&2
	exit 1
}
echo "Done."

printf "%s" "Checking if ghc works with new PREFIX..."
"${GHC_ROOT}"/bin/*-ghc --version >/dev/null || {
	echo "Failed to run ghc with new PREFIX." >&2
	exit 1
}
echo "Done."

printf "%s" "Checking whether ghc packages works with new PREFIX..."
"${GHC_ROOT}"/bin/*-ghc-pkg check || {
	echo "Failed to run ghc-pkg with new PREFIX." >&2
	exit 1
}
echo "Done."

echo "Successfully fixed PREFIX of ghc packages."
