#!/bin/bash

cd $LFS/sources
source versions.sh

BINUTILS_URI=https://mirror.freedif.org/GNU/binutils
BINUTILS_FILE=binutils-$LFS_BINUTILS_VERSION.tar.xz

GCC_URI=https://mirror.freedif.org/GNU/gcc/gcc-$LFS_GCC_VERSION
GCC_FILE=gcc-$LFS_GCC_VERSION.tar.xz

LINUX_URI=https://cdn.kernel.org/pub/linux/kernel/v$LFS_LINUX_VERSION_MAJOR.x
LINUX_FILE=linux-$LFS_LINUX_VERSION.tar.xz

MPFR_URI=https://mirror.freedif.org/GNU/mpfr
MPFR_FILE=mpfr-$LFS_MPFR_VERSION.tar.xz

GMP_URI=https://mirror.freedif.org/GNU/gmp
GMP_FILE=gmp-$LFS_GMP_VERSION.tar.xz

MPC_URI=https://mirror.freedif.org/GNU/mpc
MPC_FILE=mpc-$LFS_MPC_VERSION.tar.gz

GLIBC_URI=https://mirror.freedif.org/GNU/glibc
GLIBC_FILE=glibc-$LFS_GLIBC_VERSION.tar.xz

TCL_URI=https://prdownloads.sourceforge.net/tcl
TCL_FILE=tcl$LFS_TCL_VERSION-src.tar.gz

EXPECT_URI=https://sourceforge.net/projects/expect/files/Expect/$LFS_EXPECT_VERSION
EXPECT_FILE=expect$LFS_EXPECT_VERSION.tar.gz

DEJAGNU_URI=https://mirror.freedif.org/GNU/dejagnu
DEJAGNU_FILE=dejagnu-$LFS_DEJAGNU_VERSION.tar.gz

M4_URI=https://mirror.freedif.org/GNU/m4
M4_FILE=m4-$LFS_M4_VERSION.tar.xz

NCURSES_URI=https://mirror.freedif.org/GNU/ncurses
NCURSES_FILE=ncurses-$LFS_NCURSES_VERSION.tar.gz

BASH_URI=https://mirror.freedif.org/GNU/bash
BASH_FILE=bash-$LFS_BASH_VERSION.tar.gz

BISON_URI=https://mirror.freedif.org/GNU/bison
BISON_FILE=bison-$LFS_BISON_VERSION.tar.gz

BZIP2_URI=https://sourceware.org/pub/bzip2
BZIP2_FILE=bzip2-latest.tar.gz

COREUTILS_URI=https://mirror.freedif.org/GNU/coreutils
COREUTILS_FILE=coreutils-$LFS_COREUTILS_VERSION.tar.xz

DIFFUTILS_URI=https://mirror.freedif.org/GNU/diffutils
DIFFUTILS_FILE=diffutils-$LFS_DIFFUTILS_VERSION.tar.xz

FILE_URI=ftp://ftp.astron.com/pub/file
FILE_FILE=file-$LFS_FILE_VERSION.tar.gz

FINDUTILS_URI=https://mirror.freedif.org/GNU/findutils
FINDUTILS_FILE=findutils-$LFS_FINDUTILS_VERSION.tar.gz

GAWK_URI=https://mirror.freedif.org/GNU/gawk
GAWK_FILE=gawk-$LFS_GAWK_VERSION.tar.xz

GETTEXT_URI=https://mirror.freedif.org/GNU/gettext
GETTEXT_FILE=gettext-$LFS_GETTEXT_VERSION.tar.xz

GREP_URI=https://mirror.freedif.org/GNU/grep
GREP_FILE=grep-$LFS_GREP_VERSION.tar.xz

GZIP_URI=https://mirror.freedif.org/GNU/gzip
GZIP_FILE=gzip-$LFS_GZIP_VERSION.zip

MAKE_URI=https://mirror.freedif.org/GNU/make
MAKE_FILE=make-$LFS_MAKE_VERSION.tar.bz2

PATCH_URI=https://mirror.freedif.org/GNU/patch
PATCH_FILE=patch-$LFS_PATCH_VERSION.tar.xz

PERL_URI=https://www.cpan.org/src/$LFS_PERL_VERSION_MAJOR.0
PERL_FILE=perl-$LFS_PERL_VERSION.tar.gz

PYTHON_URI=https://www.python.org/ftp/python/$LFS_PYTHON_VERSION
PYTHON_FILE=Python-$LFS_PYTHON_VERSION.tgz

SED_URI=https://mirror.freedif.org/GNU/sed
SED_FILE=sed-$LFS_SED_VERSION.tar.xz

TAR_URI=https://mirror.freedif.org/GNU/tar
TAR_FILE=tar-latest.tar.xz

TEXINFO_URI=https://mirror.freedif.org/GNU/texinfo
TEXINFO_FILE=texinfo-$LFS_TEXINFO_VERSION.tar.gz

XZ_URI=https://tukaani.org/xz
XZ_FILE=xz-$LFS_XZ_VERSION.tar.xz

declare -a SOURCES_LIST
SOURCES_LIST=(
  BINUTILS
  GCC
  LINUX
  MPFR
  GMP
  MPC
  GLIBC
  TCL
  EXPECT
  DEJAGNU
  M4
  NCURSES
  BASH
  BISON
  BZIP2
  COREUTILS
  DIFFUTILS
  FILE
  FINDUTILS
  GAWK
  GETTEXT
  GREP
  GZIP
  MAKE
  PATCH
  PERL
  PYTHON
  SED
  TAR
  TEXINFO
  XZ
)

download_if_not_exists() {
  if [ ! -f $1 ]; then
    wget $2/$1
    #wget $2/$1.sig
    #gpg --verify $1.sig $1
  else
    echo $1 exists
  fi
}

for i in ${SOURCES_LIST[@]}; do
  i_file=$(echo $i)_FILE
  i_uri=$(echo $i)_URI
  download_if_not_exists ${!i_file} ${!i_uri}
done;

