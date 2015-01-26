{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "terminal-notifier-${version}";

  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "alloy";
    repo = "terminal-notifier";
    rev = version;
    sha256 = "0vr5kacip212a2vpm9sv17gzqhqqk4iapgpds9ympdhvlq91qjkk";
  };

  buildPhase = ''
    # TODO:
    #/usr/bin/xcodebuild
  '';

  installPhase = ''
    # TODO:
    #mkdir $out/Applications
    #cp terminal-notifier.app/Contents/MacOS/terminal-notifier
  '';

  meta = with lib; {
    maintainers = with maintainers; [ cstrahan ];
    platforms   = with platforms; darwin;
  };
}
