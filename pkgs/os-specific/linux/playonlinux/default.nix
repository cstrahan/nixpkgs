{ stdenv, lib, fetchFromGitHub, pkgconfig }:

stdenv.mkDerivation rec {
  name = "PlayOnLinux-${version}";
  version = "4.2.8";
  src = fetchFromGitHub {
    owner = "PlayOnLinux";
    repo = "POL-POM-4";
    rev = version;
    sha256 = "1a1lwlvvyf1dxp9jpkbnrhbrdik7a9qgsqg9g1sq3b42v4hq1g6k";
  };
  buildInputs = [
    pkgconfig
  ];
  installPhase = ''
    mkdir -p $out/share/playonlinux
    cp -r . $out/share/playonlinux

    mkdir -p $out/bin 
    echo "#!/bin/bash" > $out/bin/playonlinux 
    echo "$out/share/playonlinux/playonlinux \"\$@\"" >> $out/bin/playonlinux
    chmod +x  $out/bin/playonlinux

    mkdir -p $out/share/applications
    cp etc/PlayOnLinux.desktop $out/share/applications/playonlinux.desktop
    sed -i $out/share/applications/playonlinux.desktop \
      -e "s/ %F//g" \
      -e "s|/usr|$out|"
  '';
  meta = with lib; {
    description = "Software which allows you to easily install and use numerous games and apps designed to run with Microsoft® Windows®";
    homepage = "https://www.playonlinux.com/en/";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}
