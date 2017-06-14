{ stdenv, lib, fetchFromGitHub, pkgconfig, cmake, udev, audit, aws-sdk-cpp
, cryptsetup, lvm2, libgcrypt, libarchive, libgpgerror, libuuid, iptables, apt
, dpkg, lzma, lz4, bzip2, rpm, beecrypt, augeas, libxml2, sleuthkit , yara
, lldpd, google-gflags, thrift, boost163, rocksdb, cpp-netlib, glog , snappy
, openssl, linenoise-ng, file, doxygen, pythonPackages, devicemapper
, gbenchmark
, clang, llvm, lld }:

let
  thirdparty = fetchFromGitHub {
    owner = "osquery";
    repo = "third-party";
    rev = "6919841175b2c9cb2dee8986e0cfe49191ecb868";
    sha256 = "1kjxrky586jd1b2z1vs9cm7x1dxw51cizpys9kddiarapc2ih65j";
  };

in

# for reference, see:
# https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=osquery-git

stdenv.mkDerivation rec {
  name = "osquery${version}";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "facebook";
    repo = "osquery";
    rev = "62beb1e547622d63ca8793d4bc2f8eafc26e0c47";
    sha256 = "18wby13nrcd25jv6szzdb93dapgwa2slm3d81zpygz078f41b18w";
  };
  patches = [
    ./nixos.patch
    ./arch.patch
  ];

  nativeBuildInputs = [
    pkgconfig cmake
  ];

  buildInputs = [
    clang llvm lld
    gbenchmark

    udev audit lvm2 libgcrypt libarchive libgpgerror libuuid
    iptables.dev apt dpkg lzma lz4 bzip2 rpm beecrypt augeas libxml2 sleuthkit
    yara lldpd google-gflags thrift boost163 cpp-netlib glog snappy
    openssl linenoise-ng file doxygen
    devicemapper

    # we want to use the standard malloc
    (rocksdb.override { jemalloc = null; gperftools = null; })

    (aws-sdk-cpp.override {
      apis = ["firehose" "kinesis" "sts"];
      customMemoryManagement = false; # otherwise the string types don't match
      #"-DSTATIC_LINKING=1"
      #"-DNO_HTTP_CLIENT=1"
      #"-DMINIMIZE_SIZE=ON"
      #"-DBUILD_SHARED_LIBS=OFF"
    })

    pythonPackages.python pythonPackages.jinja2
  ];

  preConfigure = ''
    cp -r ${thirdparty}/* third-party
    chmod +w -R third-party

    # let cmake discover/use clang
    #unset CC
    #unset CXX

    # prefer shared libs
    export BUILD_LINK_SHARED=1

    cmakeFlagsArray+=(
      -DCMAKE_VERBOSE_MAKEFILE=ON
      "-DCMAKE_CXX_FLAGS=-I${cryptsetup}/include -I${libxml2.dev}/include/libxml2 "
      "-DCMAKE_LIBRARY_PATH=${cryptsetup}/lib"
    )
  '';
  postConfigure = ''
    #exit 1
  '';
  meta = with lib; {
    description = "...";
    homepage = "...";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}

# _ZNK5boost16re_detail_10630031cpp_regex_traits_implementationIcE9transformB5cxx11EPKcS4_
# _ZNK5boost16re_detail_10630031cpp_regex_traits_implementationIcE17transform_primaryB5cxx11EPKcS4_
