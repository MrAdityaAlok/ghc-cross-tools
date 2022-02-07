TERMUX_PKG_HOMEPAGE=https://www.haskell.org/ghc/
TERMUX_PKG_DESCRIPTION="The Glasgow Haskell Cross Compilation system for Android"
TERMUX_PKG_LICENSE="BSD 2-Clause, BSD 3-Clause, LGPL-2.1"
TERMUX_PKG_MAINTAINER="MrAdityaAlok <dev.aditya.alok@gmail.com>"
TERMUX_PKG_VERSION=8.10.7
TERMUX_PKG_SRCURL="http://downloads.haskell.org/~ghc/${TERMUX_PKG_VERSION}/ghc-${TERMUX_PKG_VERSION}-src.tar.xz"
TERMUX_PKG_SHA256=e3eef6229ce9908dfe1ea41436befb0455fefb1932559e860ad4c606b0d03c9d
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_BUILD_DEPENDS="iconv, libffi, libgmp, ncurses"

termux_step_pre_configure() {
	termux_setup_ghc

	export LIBTOOL="$(command -v libtool)"

	_WRAPPER_BIN="${TERMUX_PKG_BUILDDIR}/_wrapper/bin"
	mkdir -p "${_WRAPPER_BIN}"

	_WRAPPER_AR="${_WRAPPER_BIN}/${TERMUX_HOST_PLATFORM}-ar"
	cat >"${_WRAPPER_AR}" <<-EOF
		#!$(command -v sh)
		exec $(command -v ${AR}) "\$@"
	EOF
	chmod 0700 "${_WRAPPER_AR}"

	for tool in llc opt; do
		cat >"${_WRAPPER_BIN}/$tool" <<-EOF
			#!$(command -v sh)
			exec ${tool}-10 "\$@"
		EOF
		chmod 0700 "${_WRAPPER_BIN}/$tool"
	done

	export PATH="${_WRAPPER_BIN}:${PATH}"

	cp mk/build.mk.sample mk/build.mk
	cat >>mk/build.mk <<-EOF
		SRC_HC_OPTS        = -O -H64m
		GhcStage1HcOpts    = -O
		GhcStage2HcOpts    = -O ${_LLVM_FLAG}
		GhcLibHcOpts       = -O ${_LLVM_FLAG}
		BUILD_PROF_LIBS    = NO
		SplitSections      = YES
		HADDOCK_DOCS       = NO
		BUILD_SPHINX_HTML  = NO
		BUILD_SPHINX_PDF   = NO
		BUILD_MAN          = NO
		WITH_TERMINFO      = YES

		Stage1Only           = YES
		DYNAMIC_GHC_PROGRAMS = YES
		GhcLibWays = v dyn
		BuildFlavour = quick-cross
	EOF

	patch -Np1 <<-EOF
		--- ghc-8.10.7/rules/build-package-data.mk      2021-06-21 12:24:36.000000000 +0530
		+++ ghc-8.10.7-patch/rules/build-package-data.mk 2022-01-27 20:31:28.901997265 +0530
		@@ -68,6 +68,12 @@
		 \$1_\$2_CONFIGURE_LDFLAGS = \$\$(SRC_LD_OPTS) \$\$(\$1_LD_OPTS) \$\$(\$1_\$2_LD_OPTS)
		 \$1_\$2_CONFIGURE_CPPFLAGS = \$\$(SRC_CPP_OPTS) \$\$(CONF_CPP_OPTS_STAGE\$3) \$\$(\$1_CPP_OPTS) \$\$(\$1_\$2_CPP_OPTS)

		+ifneq "\$3" "0"
		+ \$1_\$2_CONFIGURE_LDFLAGS += $LDFLAGS
		+ \$1_\$2_CONFIGURE_CPPFLAGS += $CPPFLAGS
		+ \$1_\$2_CONFIGURE_CFLAGS += $CFLAGS
		+endif
		+
		 \$1_\$2_CONFIGURE_OPTS += --configure-option=CFLAGS="\$\$(\$1_\$2_CONFIGURE_CFLAGS)"
		 \$1_\$2_CONFIGURE_OPTS += --configure-option=LDFLAGS="\$\$(\$1_\$2_CONFIGURE_LDFLAGS)"
		 \$1_\$2_CONFIGURE_OPTS += --configure-option=CPPFLAGS="\$\$(\$1_\$2_CONFIGURE_CPPFLAGS)"
	EOF

	./utils/llvm-targets/gen-data-layout.sh >"${TERMUX_PKG_SRCDIR}/llvm-targets"
	./boot

	# if [ "${TERMUX_ARCH}" = "arm" ]; then
	# 	patch -Np1 <<-EOF
	# 		--- ghc-8.10.7/configure      2021-08-26 22:45:31.000000000 +0530
	# 		+++ ghc-8.10.7-patch/configure 2022-01-28 13:22:57.813914019 +0530
	# 		@@ -4782,7 +4782,7 @@
	# 		         llvm_target_os="\$target_os"
	# 		         ;;
	# 		   esac
	# 		-  LlvmTarget="\$llvm_target_cpu-\$llvm_target_vendor-\$llvm_target_os"
	# 		+  LlvmTarget="armv7a-unknown-linux-androideabi"
	# 	EOF
	# fi
}

termux_step_configure() {
	ghc_prefix="${TERMUX_SCRIPTDIR}/build-tools/ghc-cross-${TERMUX_PKG_VERSION}-${TERMUX_ARCH}"
	mkdir -p "$ghc_prefix"

	./configure \
		--target=${TERMUX_HOST_PLATFORM} \
		--prefix="$ghc_prefix" \
		--with-system-libffi \
		--with-ffi-includes=${TERMUX_PREFIX}/include \
		--with-ffi-libraries=${TERMUX_PREFIX}/lib \
		--with-iconv-includes=${TERMUX_PREFIX}/include \
		--with-iconv-libraries=${TERMUX_PREFIX}/lib \
		--with-gmp-includes=${TERMUX_PREFIX}/include \
		--with-gmp-libraries=${TERMUX_PREFIX}/lib \
		--with-curses-includes=${TERMUX_PREFIX}/include \
		--with-curses-libraries=${TERMUX_PREFIX}/lib \
		--with-curses-libraries-stage0=/usr/lib
}

termux_step_make() {
	make -j "${TERMUX_MAKE_PROCESSES}"
	make install

	mkdir -p "${TAR_OUTPUT_DIR}"

	tar -cJf "${TAR_OUTPUT_DIR}/ghc-${TERMUX_PKG_VERSION}-${TERMUX_ARCH}.tar.xz" -C "$ghc_prefix" .
	exit 0
}
