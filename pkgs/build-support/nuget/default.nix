{ stdenv, lib, runCommand, fetchFromGitHub, cmake, llvmPackages, mono, writeText }:

let
  nuggetDeps = runCommand "nugget-deps" {
    buildInputs = [ mono ];
    outputHashAlgo = "sha256";
    outputHash = "1ljkq9mmipl9fy11j26b2509x26s1p0iyzaamiv242jrgsl3drw1";
    outputHashMode = "recursive";
    builder = writeText "nuget-deps-builder.sh" ''
      foo
    '';
  };



stdenv.mkDerivation {
  name = "nuget-HEAD";

  src = fetchgit {
    url = https://git01.codeplex.com/nuget;
    rev = "86a4b0fb0ecb8a75dae46073e54fb0e492f5ac6c";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  buildInputs = [
    mono
  ];

  postPatch = ''
    patchShebangs .
  '';

  buildPhase = ''
    ./build.sh
  '';
}

/*
cmake
llvm-3.5
clang-3.5
lldb-3.6
lldb-3.6-dev
libunwind8
libunwind8-dev
gettext
*/
