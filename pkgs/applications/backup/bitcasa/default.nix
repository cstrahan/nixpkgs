{ stdenv, lib, fetchurl, dpkg, tree, libidn, libuuid, makeWrapper }:

stdenv.mkDerivation rec {
  name = "bitcasa2-${version}";

  version = "1.0.0.144";

  dontStrip = true;

  arch = if stdenv.is64bit then "amd64" else "i386";

  src = fetchurl {
    url = "http://dist.bitcasa.com/release/apt/pool/main/b/bitcasa2/bitcasa2_${version}_${arch}.deb";
    sha256 =
      if stdenv.is64bit
      then "04xfm49y9g3838h1bl7ikh2chwkgj3wpjl88qwfkrhjj7hkzc7rg"
      else "1mvcga6a8pni6lgvh0dm8anc0gavxjnd1f8dkwx4s9zjfdx73257";
  };

  buildInputs = [ tree dpkg makeWrapper ];

  libPath = lib.makeLibraryPath [
    libidn stdenv.cc.gcc libuuid
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir $out
    cp -r sbin $out/bin
    cp -r var/lib $out/lib
    cp -r usr/share $out/share

    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      $out/bin/mount.bitcasa

    wrapProgram $out/bin/mount.bitcasa \
      --prefix LD_LIBRARY_PATH : $libPath
  '';

}
