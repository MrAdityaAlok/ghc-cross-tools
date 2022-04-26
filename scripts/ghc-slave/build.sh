TERMUX_PKG_HOMEPAGE="https://expample.com"
TERMUX_PKG_DESCRIPTION="A sample package for testing termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=8.10.7
TERMUX_PKG_SRCURL="https://downloads.haskell.org/~ghc/${TERMUX_PKG_VERSION}/ghc-${TERMUX_PKG_VERSION}-src.tar.xz"
TERMUX_PKG_SHA256=e3eef6229ce9908dfe1ea41436befb0455fefb1932559e860ad4c606b0d03c9d
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_BUILD_DEPENDS="ghc-libs-static, libiconv, libffi, libgmp, haskell-network"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--flags=+network"

termux_step_post_get_source() {
	cp -r $TERMUX_PKG_SRCDIR/libraries/libiserv $TERMUX_PKG_SRCDIR/utils/remote-iserv
	export TERMUX_PKG_SRCDIR="${TERMUX_PKG_SRCDIR}/utils/remote-iserv"
	cd $TERMUX_PKG_SRCDIR
	cat >cabal.project <<-EOF
		packages: .
		   libiserv/
	EOF
}
