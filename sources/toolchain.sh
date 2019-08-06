#!/bin/bash

set_gcc_linker() {
  for file in gcc/config/{linux,i386/linux{,64}}.h
  do
    cp -uv $file{,.orig}
    sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
        -e 's@/usr@/tools@g' $file.orig > $file
    echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
    touch $file.orig
  done
  sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  tar xf ../mpfr-$LFS_MPFR_VERSION.tar.xz
  mv mpfr-$LFS_MPFR_VERSION mpfr
  tar xf ../gmp-$LFS_GMP_VERSION.tar.xz
  mv gmp-$LFS_GMP_VERSION gmp
  tar xf ../mpc-$LFS_MPC_VERSION.tar.gz
  mv mpc-$LFS_MPC_VERSION mpc
}

cd $LFS/sources
source versions.sh

if [ ! -f /tools/lib ]; then
  mkdir /tools/lib
fi
if [ ! -f /tools/lib64 ]; then
  ln -s lib /tools/lib64
fi

### binutils pass 1 ###
tar xf binutils-$LFS_BINUTILS_VERSION.tar.xz
cd binutils-$LFS_BINUTILS_VERSION
mkdir build
cd build
../configure --prefix=/tools --with-sysroot=$LFS --with-lib-path=/tools/lib --target=$LFS_TGT --disable-nls --disable-werror
make -j4
make install
cd $LFS/sources
rm -rf binutils-$LFS_BINUTILS_VERSION

### gcc pass 1 ###
tar xf gcc-$LFS_GCC_VERSION.tar.xz
cd gcc-$LFS_GCC_VERSION
set_gcc_linker
mkdir build
cd build
../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
make -j4
make install
cd $LFS/sources
rm -rf gcc-$LFS_GCC_VERSION

### linux headers ###
tar xf linux-$LFS_LINUX_VERSION.tar.xz
cd linux-$LFS_LINUX_VERSION
make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -r dest/include/* /tools/include
cd $LFS/sources
rm -rf linux-$LFS_LINUX_VERSION

### glibc ###
tar xf glibc-$LFS_GLIBC_VERSION.tar.xz
cd glibc-$LFS_GLIBC_VERSION
mkdir build
cd build
../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=/tools/include
make -j4
make install
cd $LFS/sources
rm -rf glibc-$LFS_GLIBC_VERSION

### libstdc++ ###
tar xf gcc-$LFS_GCC_VERSION.tar.xz
cd gcc-$LFS_GCC_VERSION
mkdir build
cd build
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/$LFS_GCC_VERSION
make -j4
make install
cd $LFS/sources
rm -rf gcc-$LFS_GCC_VERSION

### binutils pass 2 ###
tar xf binutils-$LFS_BINUTILS_VERSION.tar.xz
cd binutils-$LFS_BINUTILS_VERSION
mkdir build
cd build
CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot
make -j4
make install
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp ld/ld-new /tools/bin
cd $LFS/sources
rm -rf binutils-$LFS_BINUTILS_VERSION

### GCC pass 2 ###
tar xf gcc-$LFS_GCC_VERSION.tar.xz
cd gcc-$LFS_GCC_VERSION
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
set_gcc_linker
mkdir build
cd build
CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                       \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp
make -j4
make install
ln -sv gcc /tools/bin/cc
cd $LFS/sources
rm -rf gcc-$LFS_GCC_VERSION

### TCL ###
tar xf tcl$LFS_TCL_VERSION-src.tar.gz
cd tcl$LFS_TCL_VERSION/unix
./configure --prefix=/tools
make -j4
make install
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -s tclsh8.6 /tools/bin/tclsh
cd $LFS/sources
rm -rf tcl$LFS_TCL_VERSION

### EXPECT ###
tar xf expect$LFS_EXPECT_VERSION.tar.gz
cd expect$LFS_EXPECT_VERSION
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
make -j4
make SCRIPTS="" install
cd $LFS/sources
rm -rf expect$LFS_EXPECT_VERSION

### DEJAGNU ###
tar xf dejagnu-$LFS_DEJAGNU_VERSION.tar.gz
cd dejagnu-$LFS_DEJAGNU_VERSION
./configure --prefix=/tools
make install
cd $LFS/sources
rm -rf dejagnu-$LFS_DEJAGNU_VERSION

### m4 ###
tar xf m4-$LFS_M4_VERSION.tar.xz
cd m4-$LFS_M4_VERSION
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf m4-$LFS_M4_VERSION

### ncurses ###
tar xf ncurses-$LFS_NCURSES_VERSION.tar.gz
cd ncurses-$LFS_NCURSES_VERSION
sed -i s/mawk// configure
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make -j4
make install
ln -s libncursesw.so /tools/lib/libncurses.so
cd $LFS/sources
rm -rf ncurses-$LFS_NCURSES_VERSION

### bash ###
tar xf bash-$LFS_BASH_VERSION.tar.xz
cd bash-$LFS_BASH_VERSION
./configure --prefix=/tools --without-bash-malloc
make -j4
make install
ln -sv bash /tools/bin/sh
cd $LFS/sources
rm -rf bash-$LFS_BASH_VERSION.tar

### bison ###
tar xf bison-$LFS_BISON_VERSION.tar.gz
cd bison-$LFS_BISON_VERSION
./configure --prefix=/tools --without-bash-malloc
make -j4
make install
cd $LFS/sources
rm -rf bison-$LFS_BISON_VERSION

### bzip2 ###
tar xf bzip2-$LFS_BZIP2_VERSION.tar.gz
cd bzip2-$LFS_BZIP2_VERSION
make -j4
make PREFIX=/tools install
cd $LFS/sources
rm -rf bzip2-$LFS_BZIP2_VERSION

### coreutils ###
tar xf coreutils-$LFS_COREUTILS_VERSION.tar.xz
cd coreutils-$LFS_COREUTILS_VERSION
./configure --prefix=/tools --enable-install-program=hostname
make -j4
make install
cd $LFS/sources
rm -rf coreutils-$LFS_COREUTILS_VERSION

### diffutils ###
tar xf diffutils-$LFS_DIFFUTILS_VERSION.tar.xz
cd diffutils-$LFS_DIFFUTILS_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf diffutils-$LFS_DIFFUTILS_VERSION

### file ###
tar xf file-$LFS_FILE_VERSION.tar.gz
cd file-$LFS_FILE_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf file-$LFS_FILE_VERSION

### findutils ###
tar xf findutils-$LFS_FINDUTILS_VERSION.tar.gz
cd findutils-$LFS_FINDUTILS_VERSION
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf findutils-$LFS_FINDUTILS_VERSION

### gawk ###
tar xf gawk-$LFS_GAWK_VERSION.tar.xz
cd gawk-$LFS_GAWK_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf gawk-$LFS_GAWK_VERSION

### gettext ###
tar xf gettext-$LFS_GETTEXT_VERSION.tar.xz
cd gettext-$LFS_GETTEXT_VERSION
./configure --disable-shared
make -j4
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /tools/bin
cd $LFS/sources
rm -rf gettext-$LFS_GETTEXT_VERSION

### grep ###
tar xf grep-$LFS_GREP_VERSION.tar.xz
cd grep-$LFS_GREP_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf grep-$LFS_GREP_VERSION

### gzip ###
unzip gzip-$LFS_GZIP_VERSION.zip
cd gzip-$LFS_GZIP_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf gzip-$LFS_GZIP_VERSION

### make ###
tar xf make-$LFS_MAKE_VERSION.tar.bz2
cd make-$LFS_MAKE_VERSION
sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
./configure --prefix=/tools --without-guile
make -j4
make install
cd $LFS/sources
rm -rf make-$LFS_MAKE_VERSION

### patch ###
tar xf patch-$LFS_PATCH_VERSION.tar.xz
cd patch-$LFS_PATCH_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf patch-$LFS_PATCH_VERSION

### perl ###
tar xf perl-$LFS_PERL_VERSION.tar.gz
cd perl-$LFS_PERL_VERSION
sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth
make -j4
cp -v perl cpan/podlators/scripts/pod2man /tools/bin
mkdir -pv /tools/lib/perl$LFS_PERL_VERSION_MAJOR/$LFS_PERL_VERSION
cp -Rv lib/* /tools/lib/perl$LFS_PERL_VERSION_MAJOR/$LFS_PERL_VERSION
cd $LFS/sources
rm -rf perl-$LFS_PERL_VERSION

### Python ###
tar xf Python-$LFS_PYTHON_VERSION.tar.xz
cd Python-$LFS_PYTHON_VERSION
sed -i '/def add_multiarch_paths/a \        return' setup.py
./configure --prefix=/tools --withou-ensurepip
make -j4
make install
cd $LFS/sources
rm -rf Python-$LFS_PYTHON_VERSION

### sed ###
tar xf sed-$LFS_SED_VERSION.tar.xz
cd sed-$LFS_SED_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf sed-$LFS_SED_VERSION

### tar ###
tar xf tar-latest.tar.xz
cd tar-$LFS_TAR_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf tar-$LFS_TAR_VERSION

### texinfo ###
tar xf texinfo-$LFS_TEXINFO_VERSION.tar.gz
cd texinfo-$LFS_TEXINFO_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf texinfo-$LFS_TEXINFO_VERSION

### xz ###
tar xf xz-$LFS_XZ_VERSION.tar.xz
cd xz-$LFS_XZ_VERSION
./configure --prefix=/tools
make -j4
make install
cd $LFS/sources
rm -rf xz-$LFS_XZ_VERSION
