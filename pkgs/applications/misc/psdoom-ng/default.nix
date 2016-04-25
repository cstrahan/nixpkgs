{ stdenv, lib, fetchFromGitHub, fetchzip, pkgconfig
, SDL_mixer, SDL_net, SDL
, autoreconfHook
}:

# For reference, see the following:
# https://github.com/orsonteodoro/oiledmachine-overlay/tree/master/sys-process/psdoom-ng

#     wget -O psdoom-data.tar.gz
#     "http://downloads.sourceforge.net/project/psdoom/psdoom-data/2000.05.03/psdoom-2000.05.03-data.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fpsdoom%2Ffiles%2Fpsdoom-data%2F2000.05.03%2F&ts=1452812220&use_mirror=tcpdiag"

let
  psdoomData = fetchzip {
    name = "psdoom-data.tar.gz";
    url = "http://downloads.sourceforge.net/project/psdoom/psdoom-data/2000.05.03/psdoom-2000.05.03-data.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fpsdoom%2Ffiles%2Fpsdoom-data%2F2000.05.03%2F&ts=1452812220&use_mirror=tcpdiag";
    sha256 = "09w8jik66phfx3hjlzvvsizpklg4vkflqddg5xkikpdg252bjc26";
  };
  patch = fetchFromGitHub {
    owner = "orsonteodoro";
    repo = "psdoom-ng";
    rev = "3e92fba25a83a4361f2f848cac5529d6b3dd8003";
    sha256 = "0blr3ar1148fmqyyxcrcf3312zsp5ksq2rz5wb23nlvpdpig4n16";
  };
in
stdenv.mkDerivation rec {
  name = "psdoom-ng-${version}";
  version = "2016-01-16";
  inherit psdoomData;
  src = fetchFromGitHub {
    owner = "chocolate-doom";
    repo = "chocolate-doom";
    rev = "chocolate-doom-2.2.1";
    sha256 = "04k009r86kv2g77ay9l02rny61lj65fyg5w2kh4dljnf2k0qmf4l";
  };
  patches = [
    "${patch}/patches/psdoom-ng-2016.01.16.2.2.1.patch"
  ];
  preConfigure = ''
    mkdir -p $out/share/psdoom-ng
    cp -v ${psdoomData}/*.wad $out/share/psdoom-ng
  '';
  buildInputs = [
    autoreconfHook pkgconfig SDL_mixer SDL_net SDL
  ];
  passthru = {
    # this is so we get cached tarballs:
    inherit psdoomData patch;
  };
  meta = with lib; {
    description = "First Person Shooter operating system process killer based on psDooM and Chocolate Doom";
    homepage = "https://github.com/orsonteodoro/psdoom-ng";
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}
