{ stdenv, lib, fetchFromGitHub, pkgconfig, cmake, boost, openexr, openimageio }:

stdenv.mkDerivation rec {
  name = "universalscenedescription-${version}";
  version = "0.7.0";
  src = fetchFromGitHub {
    owner = "PixarAnimationStudios";
    repo = "USD";
    rev = "v${version}";
    sha256 = "1cis3cv1k7wzfgdciazwbvcqm72qmfnvrk6sxqkmdvfxs36nf56c";
  };
  buildInputs = [
    pkgconfig cmake openexr openimageio
  ];
  meta = with lib; {
    description = "Efficient, scalable system for authoring, reading, and streaming time-sampled scene description for interchange between graphics applications";
    homepage = "http://graphics.pixar.com/usd/docs/index.html";
    license = licenses.free; # "Modified Apache 2.0" -- not sure what to put here.
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}
