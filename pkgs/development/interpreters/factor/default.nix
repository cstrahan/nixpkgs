{ stdenv
http://downloads.factorcode.org/releases/0.96/factor-src-0.96.zip
bbba60025e5e096967550eaf0b84f83e5ee67889fa2ab611c3b96b73f170028c

deps: libc6-dev libpango1.0-dev libx11-dev xorg-dev libgtk2.0-dev gtk2-engines-pixbuf libgtkglext1-dev wget git git-doc rlwrap gcc g++ make

build() {
    _bootimg="boot.unix-x86.32.image"
    cd $srcdir/$pkgname
    patch -p1 < $srcdir/fuel-factor-vm.patch
    make
    ./factor -i=$_bootimg
}

parse_build_info() {
    ensure_program_installed cut
    $ECHO "Parsing make target from command line: $1"
    OS=`echo $1 | cut -d '-' -f 1`
    ARCH=`echo $1 | cut -d '-' -f 2`
    WORD=`echo $1 | cut -d '-' -f 3`
    
    if [[ $OS == linux && $ARCH == ppc ]] ; then WORD=32; fi
    if [[ $OS == linux && $ARCH == arm ]] ; then WORD=32; fi
    if [[ $OS == macosx && $ARCH == ppc ]] ; then WORD=32; fi
    
    $ECHO "OS=$OS"
    $ECHO "ARCH=$ARCH"
    $ECHO "WORD=$WORD"
}


set_build_info() {
    check_os_arch_word
    if [[ $OS == linux && $ARCH == ppc ]] ; then
        MAKE_IMAGE_TARGET=linux-ppc.32
        MAKE_TARGET=linux-ppc-32
    elif [[ $OS == windows && $ARCH == x86 && $WORD == 64 ]] ; then
        MAKE_IMAGE_TARGET=windows-x86.64
        MAKE_TARGET=windows-x86-64
    elif [[ $OS == windows && $ARCH == x86 && $WORD == 32 ]] ; then
        MAKE_IMAGE_TARGET=windows-x86.32
        MAKE_TARGET=windows-x86-32
    elif [[ $ARCH == x86 && $WORD == 64 ]] ; then
        MAKE_IMAGE_TARGET=unix-x86.64
        MAKE_TARGET=$OS-x86-64
    elif [[ $ARCH == x86 && $WORD == 32 ]] ; then
        MAKE_IMAGE_TARGET=unix-x86.32
        MAKE_TARGET=$OS-x86-32
    else
        MAKE_IMAGE_TARGET=$ARCH.$WORD
        MAKE_TARGET=$OS-$ARCH-$WORD
    fi
    BOOT_IMAGE=boot.$MAKE_IMAGE_TARGET.image
}

  installPhase = ''
    mkdir -p "${out}/bin"
    mkdir -p "${out}/lib/factor"
    mkdir -p "${out}/share/applications"
    mkdir -p "${out}/share/pixmaps"

    # copy over the stdlib
    cp -a misc extra core basis factor.image "${out}/lib/factor/"

    # copy over the bin
    cp factor "${out}/bin/"

    # add the desktop entry
    cp "factor.desktop" "${out}/share/applications/factor.desktop"
    cp "factor.svg" "${out}/share/pixmaps/factor.svg"
  '';
}
