# https://github.com/dotnet/coreclr/wiki/Linux-Instructions
# https://github.com/dotnet/coreclr/issues/170

{ stdenv, lib, fetchFromGitHub, cmake, llvm, mono, writeText, libunwind, gettext }:

let
  #nuggetDeps = runCommand "nugget-deps" {
  #  buildInputs = [ mono ];
  #  outputHashAlgo = "sha256";
  #  outputHash = "1ljkq9mmipl9fy11j26b2509x26s1p0iyzaamiv242jrgsl3drw1";
  #  outputHashMode = "recursive";
  #  builder = writeText "nuget-deps-builder.sh" ''
  #    foo
  #  '';
  #};

in stdenv.mkDerivation {
  name = "coreclr-HEAD";

  #src = fetchFromGitHub {
  #  owner = "dotnet";
  #  repo = "coreclr";
  #  rev = "f630092301c53fc88419900039e9fd6fc94be9d0";
  #  sha256 = "1ljkq9mmipl9fy11j26b2509x26s1p0iyzaamiv242jrgsl3drw1";
  #};
  src = fetchFromGitHub {
    owner = "akoeplinger";
    repo = "coreclr";
    rev = "099f326ea7778fa73f915ea7cfb666b5fbdc4d05";
    sha256 = "0aza0xp0vm37brwvcrl8nm2l951ax60h2g80apf2i8mzavdw3921";
  };

  # This is a bit of a hack.
  # We want to get the right env vars,
  # but we don't actually want to invoke cmake just yet.
  dontUseCmakeConfigure = true;
  configurePhase = ''
    mkdir hack
    echo "#!${stdenv.shell}" > cmake
    chmod +x hack/cmake

    _PATH=$PATH
    PATH=$PATH:$(pwd)/hack

    cmakeConfigurePhase

    PATH=$_PATH
    rm -r hack
  '';

  buildInputs = [
    mono
    cmake
    #llvmPackages.lldb
    llvm
    libunwind
    gettext
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
