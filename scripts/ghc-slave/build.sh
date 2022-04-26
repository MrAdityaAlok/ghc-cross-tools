TERMUX_PKG_HOMEPAGE="https://expample.com"
TERMUX_PKG_DESCRIPTION="A sample package for testing termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=8.10.7
TERMUX_PKG_SRCURL="https://downloads.haskell.org/~ghc/${TERMUX_PKG_VERSION}/ghc-${TERMUX_PKG_VERSION}-src.tar.xz"
TERMUX_PKG_SHA256=e3eef6229ce9908dfe1ea41436befb0455fefb1932559e860ad4c606b0d03c9d
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_BUILD_DEPENDS="ghc-libs-static, haskell-network"

termux_step_configure() {
	termux_setup_cabal
	termux_setup_jailbreak_cabal
	termux_setup_ghc_cross_compiler
	cd $TERMUX_PKG_SRCDIR/libraries/libiserv
	jailbreak-cabal ./*.cabal
	cabal configure \
		--enable-static \
		--prefix=$TERMUX_PREFIX \
		--configure-option=--disable-rpath \
		--configure-option=--disable-rpath-hack \
		--ghc-option=-optl-Wl,-rpath=$TERMUX_PREFIX/lib \
		--ghc-option=-optl-Wl,--enable-new-dtags \
		--with-compiler="$(command -v termux-ghc)" \
		--with-ghc-pkg="$(command -v termux-ghc-pkg)" \
		--with-hsc2hs="$(command -v termux-hsc2hs)" \
		--hsc2hs-option=--cross-compile \
		--with-ld=$LD \
		--with-strip=$STRIP \
		--with-ar=$AR \
		--with-pkg-config=$PKG_CONFIG \
		--with-happy="$(command -v happy)" \
		--with-alex="$(command -v alex)" \
		--extra-include-dirs=$TERMUX_PREFIX/include \
		--extra-lib-dirs=$TERMUX_PREFIX/lib \
		--disable-tests \
		--enable-executable-static
}

termux_step_make() {
	cd $TERMUX_PKG_SRCDIR/libraries/libiserv
	cabal build
}
termux_step_make_install() {
	cd $TERMUX_PKG_SRCDIR/libraries/libiserv
	cabal install
}
