{ stdenv, fetchurl, fetchFromGitHub, which, clang
, libcap, linuxHeaders, libuv, imagemagick, discount, protobuf, coreutils
}:

# XXX WARNING XXX
# This package includes several others by source.
# * This should not be taken as a guideline of what to do in general packaging.
# * This package does not benefit from build caching.
# * This package needs versions updated separately in case of security issues.
# * Dependency build mechanisms cannot be easily overridden.

# In the long run, someone (possibly me (maurer)) should figure out how to
# convince sandstorm/ekam to build against provided libraries.

stdenv.mkDerivation rec {
  name = "sandstorm-${version}";
  version = "broken";
  capnproto = fetchFromGitHub {
    owner  = "sandstorm-io";
    repo   = "capnproto";
    rev    = "ee64a2125c56bd897556aec07c8b33543e2d64cf";
    sha256 = "0jfv5hnng8bd6w2rg0mfgyd5hqqx49x2xp3cp9b9g5yp3njyzk1k";
  };
  ekam = fetchFromGitHub {
    owner  = "sandstorm-io";
    repo   = "ekam";
    rev    = "55b768c3a4bf6160596a47166f82f6b9e8ba4125";
    sha256 = "0qsm40vf2hh3vddlfms6fgjdpdsfndkwm0bzlama9pxj7di7pqkf";
  };
  libseccomp = fetchFromGitHub {
    owner  = "seccomp";
    repo   = "libseccomp";
    rev    = "d5fd8b95a86509af7b901e2b81ec9d61352b89e4";
    sha256 = "034k1gn6mzsagh6vxj12bbjjj2l3y5k3gig063vsbi09xkynq3dj";
  };
  libsodium = fetchurl {
    url = "https://download.libsodium.org/libsodium/releases/libsodium-1.0.6.tar.gz";
    sha256 = "0ngvcjwg6m9nivzi208yvz8yvmk6kxnvyr25w907kaicgpm063cl";
  };
  #libsodium = fetchFromGitHub {
  #  owner  = "jedisct1";
  #  repo   = "libsodium";
  #  rev    = "stable";
  #  sha256 = "1rwzdljawy64ilja3vhxg8zfq22ch6r60jc775a48nvbf6q5ssmq";
  #};
  es6-promise = fetchurl {
    url = "https://es6-promises.s3.amazonaws.com/es6-promise-2.0.1.min.js";
    sha256 = "173icn99hcfi9yigv6d35vrh0w7i3yyphd68avy19v8wdj8kwhjg";
  };
  sandstorm-rev = "e75892f47a51521b063d60b2c36c0a1acd79e0f2";
  sandstorm-src = fetchFromGitHub {
    owner  = "sandstorm-io";
    repo   = "sandstorm";
    rev    = sandstorm-rev;
    sha256 = "0lkqv85ngmwfj67vg5mh1j5vngbsjzm1fl9fh1ihdddl8sj2qgjj";
  };
  srcs = [ capnproto ekam libseccomp libsodium sandstorm-src ];
  buildInputs = [ libcap linuxHeaders clang which libuv imagemagick
                  discount protobuf coreutils ];
  sourceRoot = "sandstorm-${sandstorm-rev}-src";
  patches = [ ./dedep.patch ];
  postUnpack = ''
    # Load deps into deps folder.
    # Use cp instead of ln to avoid permission issues
    mkdir -p ${sourceRoot}/deps
    cp -r `realpath capnproto*`  ${sourceRoot}/deps/capnproto
    cp -r `realpath ekam*`       ${sourceRoot}/deps/ekam
    cp -r `realpath libseccomp*` ${sourceRoot}/deps/libseccomp
    cp -r `realpath libsodium*`  ${sourceRoot}/deps/libsodium

    # Files are created in here, we need to make sources writeable
    chmod -R u+rw ${sourceRoot}/deps
    mkdir -p tmp

    # Tries to use the network
    rm ${sourceRoot}/deps/capnproto/c++/src/kj/async-io-test.c++
  '';
  postPatch = ''
    # We don't have traditional /usr/include
    sed -e 's#/usr/include/linux#${linuxHeaders}/include/linux#' \
      -i src/sandstorm/ip_tables.ekam-rule
    # We don't have a /bin/true
    sed -e 's#/bin/true#${coreutils}/bin/true#' \
      -i src/sandstorm/util-test.c++
  '';
  # Ekam uses "intercept.so", a trick for fake filesystems. NIX_ENFORCE_PURITY
  # prevents this, so we disable purity during building.
  buildPhase = ''
    NIX_ENFORCE_PURITY=0 make tmp/.ekam-run
  '';
  installPhase = ''
    install -D bin/spk $out/bin/spk
    install -D bin/sandstorm $out/bin/sandstorm
    install -D bin/sandstorm-http-bridge $out/bin/sandstorm-http-bridge
  '';
}
