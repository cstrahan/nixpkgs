{ stdenv, lib, fetchFromGitHub, pkgconfig, cmake, pythonPackages
, udev
, audit
, aws-sdk-cpp
, cryptsetup
, lvm2
, libgcrypt
, libarchive
, libgpgerror
, libuuid
, iptables
, apt
, dpkg
, lzma
, lz4
, bzip2
, rpm
, beecrypt
, augeas
, libxml2
, sleuthkit
, yara
, lldpd
, google-gflags
, thrift
, boost
, rocksdb
, cpp-netlib
, glog
, gbenchmark
, snappy
, openssl
, linenoise-ng
, file
, doxygen
, devicemapper
, clangStdenv
}:

let
  thirdparty = fetchFromGitHub {
    owner = "osquery";
    repo = "third-party";
    rev = "6919841175b2c9cb2dee8986e0cfe49191ecb868";
    sha256 = "1kjxrky586jd1b2z1vs9cm7x1dxw51cizpys9kddiarapc2ih65j";
  };

in

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
  buildInputs = [
    pkgconfig cmake python

    udev audit

    (aws-sdk-cpp.override {
      apis = [ "firehose" "kinesis" "sts" ];
      customMemoryManagement = false;
    })

    lvm2 libgcrypt libarchive libgpgerror libuuid iptables.dev apt dpkg lzma lz4
    bzip2 rpm beecrypt augeas libxml2 sleuthkit
    yara lldpd google-gflags thrift boost
    cpp-netlib glog gbenchmark snappy openssl linenoise-ng
    file /* for libmagic */ doxygen devicemapper cryptsetup

    (rocksdb.override { jemalloc = null; gperftools = null; })

    pythonPackages.python
    pythonPackages.jinja2
];

  preConfigure = ''
    export NIX_CFLAGS_COMPILE="-I${libxml2.dev}/include/libxml2 $NIX_CFLAGS_COMPILE"

    echo $NIX_LDFLAGS
    echo ===============
    echo $NIX_CFLAGS_COMPILE

    cmakeFlagsArray+=(
      -DCMAKE_LIBRARY_PATH=${cryptsetup}/lib
      -DCMAKE_VERBOSE_MAKEFILE=ON
    )

    cp -r ${thirdparty}/* third-party
    chmod +w -R third-party
  '';
  preBuild = ''
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
