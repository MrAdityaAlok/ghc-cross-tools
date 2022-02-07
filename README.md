# GHC cross-compiler

GHC cross-compiler targeting Android.

### Available for archs

- aarch64/arm64
- arm/arm32
- i686
- x86_64

# Installation

- Download GHC from [releases](https://github.com/MrAdityaAlok/termux-ghc-cross-compiler/releases)

GHC packages have PREFIX (used while building them) embedded into there configuration files.
Therefore, it should be replaced with path to the installation directory to make it work from that directory.

To replace it with another PREFIX use `fix-path.sh` script from this repository.

Run as:

```
./fix-path.sh <path to directory where GHC has been unpacked/installed, i.e GHC ROOT>
```
