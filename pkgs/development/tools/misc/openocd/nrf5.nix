{ stdenv, lib, fetchgit, fetchFromGitHub, libftdi, libusb1, pkgconfig, hidapi
, automake, autoconf, libtool, tcl }:

let
  jimtcl = fetchgit {
    url = "git://repo.or.cz/jimtcl.git";
    rev = "51f65c6d38fbf86e1f0b036ad336761fd2ab7fa0";
    sha256 = "00ldal1w9ysyfmx28xdcaz81vaazr1fqixxb2abk438yfpp1i9hq";
  };

  libjaylink = fetchgit {
    url = "git://repo.or.cz/libjaylink.git";
    rev = "24b8ce72c651d136825e4a8793ece6396251f2f1";
    sha256 = "1w456gb2inmh598hlf25c7yc8fwrkffmyn2qhm31lcmi7rgfaw6i";
  };

in

stdenv.mkDerivation rec {
  name = "openocd-nrf5-${version}";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "sandeepmistry";
    repo = "openocd-code-nrf5";
    rev = "57a19d4ec8a848b66135e81a53c78d9ff58e1d3e";
    sha256 = "0c07pkrsyzxj8mp859hwlk935357d65gfiw1fdahmg8bg1svfvn5";
  };

  buildInputs = [ libftdi libusb1 pkgconfig hidapi automake autoconf libtool ];

  configureFlags = [
    "--enable-jtag_vpi"
    "--enable-usb_blaster_libftdi"
    "--enable-amtjtagaccel"
    "--enable-gw16012"
    "--enable-presto_libftdi"
    "--enable-openjtag_ftdi"
    "--enable-oocd_trace"
    "--enable-buspirate"
    "--enable-sysfsgpio"
    "--enable-remote-bitbang"
  ];

  preConfigure = ''
    cp -r ${jimtcl}/. jimtcl
    chmod -R +w jimtcl

    cp -r ${libjaylink}/. src/jtag/drivers/libjaylink
    chmod -R +w src/jtag/drivers/libjaylink

    PATH=$PATH:${lib.makeBinPath [tcl]}

    # copied from ./bootstrap
    aclocal
    libtoolize --automake --copy
    autoconf
    autoheader
    automake --gnu --add-missing --copy
  '';

  postInstall = ''
    mkdir -p "$out/etc/udev/rules.d"
    rules="$out/share/openocd/contrib/99-openocd.rules"
    if [ ! -f "$rules" ]; then
        echo "$rules is missing, must update the Nix file."
        exit 1
    fi
    ln -s "$rules" "$out/etc/udev/rules.d/"
  '';

  meta = with stdenv.lib; {
    description = "Free and Open On-Chip Debugging, In-System Programming and Boundary-Scan Testing";
    longDescription = ''
      OpenOCD provides on-chip programming and debugging support with a layered
      architecture of JTAG interface and TAP support, debug target support
      (e.g. ARM, MIPS), and flash chip drivers (e.g. CFI, NAND, etc.).  Several
      network interfaces are available for interactiving with OpenOCD: HTTP,
      telnet, TCL, and GDB.  The GDB server enables OpenOCD to function as a
      "remote target" for source-level debugging of embedded systems using the
      GNU GDB program.
    '';
    homepage = https://github.com/sandeepmistry/openocd-code-nrf5;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ cstrahan ];
    platforms = platforms.linux;
  };
}
