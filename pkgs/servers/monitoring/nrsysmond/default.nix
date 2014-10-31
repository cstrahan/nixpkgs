{ stdenv, lib, fetchurl, dpkg, patchelf }:

assert stdenv.system == "i686-linux" || stdenv.system == "x86_64-linux";

let
  version = "1.5.0.81";
  arch = if stdenv.system == "is868-linux"
         then "i386"
         else "amd64";

in

stdenv.mkDerivation {
  name = "nrsysmond-${version}";
  src = fetchurl {
    url = "https://download.newrelic.com/debian/dists/newrelic/non-free/binary-${arch}/newrelic-sysmond_${version}_${arch}.deb";
    sha256 = "0c2n19haj3hn2m6p7zmpw44dpwxik2a2valz3g2q32bcq3qy0jnd";
  };
  buildInputs = [ dpkg ];
  unpackPhase = ''
    mkdir pkg
    dpkg-deb -x $src pkg
    sourceRoot=pkg
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp usr/sbin/* $out/bin
    ${patchelf}/bin/patchelf \
      --interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" \
      $out/bin/nrsysmond
  '';
}
