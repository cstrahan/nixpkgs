{ stdenv, lib, fetchFromGitHub, pkgconfig, cmake }:

stdenv.mkDerivation rec {
  name = "rapidjson-${version}";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "miloyip";
    repo = "rapidjson";
    rev = "v${version}";
    sha256 = "1jixgb8w97l9gdh3inihz7avz7i770gy2j2irvvlyrq3wi41f5ab";
  };

  nativeBuildInputs = [ pkgconfig cmake
  ];

  meta = with lib; {
    description = "...";
    homepage = "...";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}
