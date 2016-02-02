{ stdenv, lib, fetchFromGitHub, pkgconfig, openssl, makeWrapper, python, coreutils }:

stdenv.mkDerivation rec {
  name = "cipherscan";
  src = fetchFromGitHub {
    owner = "jvehent";
    repo = "cipherscan";
    rev = "18b0d1b952d027d20e38f07329817873ec077d26";
    sha256 = "0b6fkfm2y8w04am4krspmapcc5ngn603n5rlwyjly92z2dawc7h8";
  };
  buildInputs = [ makeWrapper python ];
  patches = [ ./path.patch ];
  buildPhase = ''
    substituteInPlace cipherscan \
      --replace "@OPENSSLBIN@" \
                "${openssl}/bin/openssl" \
      --replace "@TIMEOUTBIN@" \
                "${coreutils}/bin/timeout" \
      --replace "@READLINKBIN@" \
                "${coreutils}/bin/readlink"

    substituteInPlace analyze.py \
      --replace "@OPENSSLBIN@" \
                "${openssl}/bin/openssl"
  '';
  installPhase = ''
    mkdir -p $out/bin

    cp cipherscan $out/bin
    cp openssl.cnf $out/bin
    cp analyze.py $out/bin

    wrapProgram $out/bin/analyze.py --set PYTHONPATH "$PYTHONPATH"
  '';
  meta = with lib; {
    description = "...";
    homepage = "...";
    license = licenses.mpl;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ cstrahan ];
  };
}
