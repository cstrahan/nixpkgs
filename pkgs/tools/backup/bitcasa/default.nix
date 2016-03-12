{ stdenv, lib, fetchurl, patchelf, dpkg, libidn, zlib, libuuid, makeWrapper
, libredirect, writeText }:

let
  version = "0.9.9.126";
  rpath = 
    lib.makeLibraryPath [ stdenv.cc.cc zlib libidn libuuid ];
  src =
    if stdenv.system == "i686-linux" then fetchurl {
      url = "http://dist.bitcasa.com/release/apt/pool/main/b/bitcasa/bitcasa_${version}_i386.deb";
      sha256 = "0f7ys0yjdzz73yv63d6pj2jbh1nxrn6ir0542ps2921pa81hvrc3";
    } else fetchurl {
      url = "http://dist.bitcasa.com/release/apt/pool/main/b/bitcasa/bitcasa_${version}_amd64.deb";
      sha256 = "1yzrw1vrhfbmym6l6wb2c4jwc834s4cl862ci7w1fyy6z1698k0p";
    };
  # mount.bitcasa tries to parse /etc/issue and segfaults.
  etcIssue = writeText "issue" ''
    Ubuntu 13.04 \n \l
  '';
  redirects = [
    "/etc/issue=${etcIssue}"
  ];

in

stdenv.mkDerivation rec {
  name = "bitcasa-${version}";
  inherit version src;
  buildInputs = [ dpkg makeWrapper ];
  dontStrip = true;
  unpackPhase = ''
    mkdir pkg
    dpkg-deb -x $src pkg
    sourceRoot=pkg
  '';
  buildPhase = ''
    ${patchelf}/bin/patchelf \
      --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${rpath}" \
      "sbin/mount.bitcasa"
  '';
  installPhase = ''
    install -d "$pkgdir/bin"

    # Install Mount binary
    install -Dm755 "sbin/mount.bitcasa" "$out/bin/mount.bitcasa"

    # Install Share files
    for i in de en en_GB es fr it ja ko pt zh_CN zh_TW
    do
      install -d "$out/share/locale/$i/LC_MESSAGES"
      install -Dm644 "usr/share/locale/$i/LC_MESSAGES/Bitcasa.mo" "$out/share/locale/$i/LC_MESSAGES/Bitcasa.mo"
      install -d "$out/share/man/$i/man8"
      install -Dm644 "usr/share/man/$i/man8/mount.bitcasa.8.gz" "$out/share/man/$i/man8/mount.bitcasa.8.gz"
    done

    # Install var files
    install -d "$out/var/lib/bitcasa"
    install -Dm644 "var/lib/bitcasa/ca.pem" "$out/var/lib/bitcasa/ca.pem"
    install -Dm644 "var/lib/bitcasa/cache.conf" "$out/var/lib/bitcasa/cache.conf"

    wrapProgram $out/bin/mount.bitcasa \
      --set LD_PRELOAD "${libredirect}/lib/libredirect.so" \
      --set NIX_REDIRECTS "${builtins.concatStringsSep ":" redirects}"
  '';
    #${patchelf}/bin/patchelf \
    #  --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
    #  $out/bin/rescuetime
  meta = with lib; {
    description = "...";
    homepage = "...";
    license = licenses.unfree;
    platforms   = [ "i686-linux" "x86_64-linux" ];
    maintainers = with maintainers; [ cstrahan ];
  };
}
