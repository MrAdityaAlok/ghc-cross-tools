TERMUX_PKG_HOMEPAGE=https://www.haskell.org/ghc/
TERMUX_PKG_DESCRIPTION="The Glasgow Haskell Compiler"
TERMUX_PKG_LICENSE="BSD 2-Clause, BSD 3-Clause, LGPL-2.1"
TERMUX_PKG_MAINTAINER="Aditya Alok <alok@termux.org>"
TERMUX_PKG_VERSION=9.2.5
TERMUX_PKG_SRCURL="https://downloads.haskell.org/~ghc/${TERMUX_PKG_VERSION}/ghc-${TERMUX_PKG_VERSION}-src.tar.xz"
TERMUX_PKG_SHA256=0606797d1b38e2d88ee2243f38ec6b9a1aa93e9b578e95f0de9a9c0a4144021c
TERMUX_PKG_DEPENDS="iconv, libffi, ncurses, libgmp, libandroid-posix-semaphore"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-ld-override
--build=x86_64-unknown-linux
--host=x86_64-unknown-linux
--with-system-libffi
--with-ffi-includes=${TERMUX_PREFIX}/include
--with-ffi-libraries=${TERMUX_PREFIX}/lib
--with-gmp-includes=${TERMUX_PREFIX}/include
--with-gmp-libraries=${TERMUX_PREFIX}/lib
--with-iconv-includes=${TERMUX_PREFIX}/include
--with-iconv-libraries=${TERMUX_PREFIX}/lib
--with-curses-libraries=${TERMUX_PREFIX}/lib
--with-curses-includes=${TERMUX_PREFIX}/include
"
TERMUX_PKG_NO_STATICSPLIT=true

termux_step_pre_configure() {
	termux_setup_ghc

	local host_platform="${TERMUX_HOST_PLATFORM}"
	[ "${TERMUX_ARCH}" = "arm" ] && host_platform="armv7a-linux-androideabi"
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --target=${host_platform}"

	local wrapper_bin="${TERMUX_PKG_BUILDDIR}/_wrapper/bin"
	mkdir -p "${wrapper_bin}"

	for tool in llc opt; do
		local wrapper="${wrapper_bin}/${tool}"
		cat >"$wrapper" <<-EOF
			#!$(command -v sh)
			exec /usr/lib/llvm-12/bin/${tool} "\$@"
		EOF
		chmod 0700 "$wrapper"
	done

	local ar_wrapper="${wrapper_bin}/${host_platform}-ar"
	cat >"$ar_wrapper" <<-EOF
		#!$(command -v sh)
		exec $(command -v "${AR}") "\$@"
	EOF
	chmod 0700 "$ar_wrapper"

	export PATH="${wrapper_bin}:${PATH}"

	local extra_flags="-O -optl-Wl,-rpath=${TERMUX_PREFIX}/lib -optl-Wl,--enable-new-dtags"
	[ "${TERMUX_ARCH}" != "i686" ] && extra_flags+=" -fllvm"

	# Suppress warnings for LLVM 13
	sed -i 's/LlvmMaxVersion=13/LlvmMaxVersion=15/' configure.ac

	export LIBTOOL && LIBTOOL="$(command -v libtool)"

	cp mk/build.mk.sample mk/build.mk
	cat >>mk/build.mk <<-EOF
		Stage1Only         = YES
		SRC_HC_OPTS        = -O -H64m
		GhcStage1HcOpts    = -O
		GhcLibHcOpts       = ${extra_flags} -optl-landroid-posix-semaphore
		BuildFlavour       = quick-cross
		GhcLibWays         = v
		BUILD_PROF_LIBS    = NO
		HADDOCK_DOCS       = NO
		BUILD_SPHINX_HTML  = NO
		BUILD_SPHINX_PDF   = NO
		BUILD_MAN          = NO
		DYNAMIC_GHC_PROGRAMS = NO
	EOF

	patch -p1 <<-EOF
		--- ghc.orig/rules/build-package-data.mk 2022-11-07 01:10:29.000000000 +0530
		+++ ghc.mod/rules/build-package-data.mk  2022-11-11 13:08:01.992488180 +0530
		@@ -68,6 +68,12 @@
		 \$1_\$2_CONFIGURE_LDFLAGS = \$\$(SRC_LD_OPTS) \$\$(\$1_LD_OPTS) \$\$(\$1_\$2_LD_OPTS)
		 \$1_\$2_CONFIGURE_CPPFLAGS = \$\$(SRC_CPP_OPTS) \$\$(CONF_CPP_OPTS_STAGE\$3) \$\$(\$1_CPP_OPTS) \$\$(\$1_\$2_CPP_OPTS)

		+ifneq "\$3" "0"
		+ \$1_\$2_CONFIGURE_LDFLAGS += ${LDFLAGS}
		+ \$1_\$2_CONFIGURE_CPPFLAGS += ${CPPFLAGS}
		+ \$1_\$2_CONFIGURE_CFLAGS += ${CFLAGS}
		+endif
		+
		 \$1_\$2_CONFIGURE_OPTS += --configure-option=CFLAGS="\$\$(\$1_\$2_CONFIGURE_CFLAGS)"
		 \$1_\$2_CONFIGURE_OPTS += --configure-option=LDFLAGS="\$\$(\$1_\$2_CONFIGURE_LDFLAGS)"
		 \$1_\$2_CONFIGURE_OPTS += --configure-option=CPPFLAGS="\$\$(\$1_\$2_CONFIGURE_CPPFLAGS)"
		@@ -104,9 +110,12 @@
		 \$1_\$2_CONFIGURE_OPTS += --configure-option=--with-gmp
		 endif

		-
		 ifneq "\$\$(CURSES_LIB_DIRS)" ""
		-\$1_\$2_CONFIGURE_OPTS += --configure-option=--with-curses-libraries="\$\$(CURSES_LIB_DIRS)"
		+ ifeq "\$3" "0"
		+  \$1_\$2_CONFIGURE_OPTS += --configure-option=--with-curses-libraries="/usr/lib"
		+ else
		+  \$1_\$2_CONFIGURE_OPTS += --configure-option=--with-curses-libraries="\$\$(CURSES_LIB_DIRS)"
		+ endif
		 endif

		 \$1_\$2_CONFIGURE_OPTS += --configure-option=--host=\$(TargetPlatformFull)
	EOF

	./boot
}

termux_step_make_install() {
	make install-strip INSTALL="$(command -v install) --strip-program=${STRIP}"
	# Pack now since we need dependency libs too.
	tar -cvzf "$TAR_OUTPUT_DIR/ghc-$TERMUX_PKG_VERSION-$TERMUX_ARCH.tar.xz" ./lib/ ./bin/ ./include -C "$TERMUX_PREFIX"
	exit
}
