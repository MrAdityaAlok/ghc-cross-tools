TERMUX_PKG_HOMEPAGE="https://expample.com"
TERMUX_PKG_DESCRIPTION="A sample package for testing termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=8.10.7
TERMUX_PKG_SRCURL="http://downloads.haskell.org/~ghc/${TERMUX_PKG_VERSION}/ghc-${TERMUX_PKG_VERSION}-src.tar.xz"
TERMUX_PKG_SHA256=e3eef6229ce9908dfe1ea41436befb0455fefb1932559e860ad4c606b0d03c9d
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_BUILD_DEPENDS="ghc-libs-static, haskell-network"

termux_step_make() {
	termux_setup_cabal
	termux_setup_jailbreak_cabal
	termux_setup_ghc_cross_compiler
	cd $TERMUX_PKG_SRCDIR/libraries/libiserv
	jailbreak-cabal ./*.cabal
	cabal configure \
		--enable-static \
		--disable-shared \
		--with-ghc=termux-ghc \
		--with-ghc-pkg=termux-ghc-pkg \
		--flags=+network \
		--prefix=$TERMUX_PREFIX \
		--enable-executable-static
	cabal build
	cabal install
}
