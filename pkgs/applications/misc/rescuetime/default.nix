{ stdenv, dpkg, patchelf }:

assert stdenv.system == "i686-linux" || stdenv.system == "x86_64-linux";
let
  src =
    if stdenv.system == "is868-linux" then fetchurl {
      url = "https://www.rescuetime.com/setup/installer?os=i386deb";
      sha256 = "";
    } else fetchurl {
      url = "https://www.rescuetime.com/setup/installer?os=amd64deb";
      sha256 = "";
    };

in

stdenv.mkDerivation {
  name = "rescuetime";
  inherit src;
  buildInputs = [ dpkg ];
  unpackPhase = ''
    mkdir pkg
    dpkg-deb -x $src pkg
    sourceRoot=pkg
  '';
  installPhase = ''
    #mkdir -p $out/bin
    #cp usr/sbin/* $out/bin
    #${patchelf}/bin/patchelf \
    #  --interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" \
    #  $out/bin/rescuetime
  '';
}
