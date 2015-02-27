{ stdenv, fetchsvn, fetchgit, ninja, python, pythonPackages, coreutils, jdk, pkgconfig
, gtk, mesa, libXtst, pciutils, dbus_glib, glib, GConf, nss, nspr

}:

# see: http://www.webrtc.org/native-code/development
#      https://github.com/fd/webrtc/blob/master/build/linux_amd64/bin/build
#      https://aur.archlinux.org/packages/li/libwebrtc-static/PKGBUILD
#
# TODO: use depot tools to fetch the sources locally,
#       then take note of the directory structure,
#       that way I know what deps I need to fetch, and from where.
stdenv.mkDerivation rec {
  name = "webrtc-HEAD";

  buildType = "Release";
  buildPath = "out/${buildType}";
  target = "All";

  buildInputs = [
dbus_glib
    #glib
    nspr
    nss
    GConf
    pciutils
    pkgconfig
    gtk mesa
    libXtst
    jdk
    python
    pythonPackages.gyp pythonPackages.ply pythonPackages.jinja2
  ];

  chromium_git = "https://chromium.googlesource.com";

  #src/third_party/libvpx':
  libvpx = fetchgit {
    url = "${chromium_git}/chromium/deps/libvpx.git";
    rev = "33bbffe8b3fa6d240ab7720f4f46854bd98d7198";
    sha256 = "0m6hdg1jjj0a70szaqchxs21w0d5cvbvnmkhayr46yjrl9awbf6s";
  };
  #src/third_party/libyuv':
  libyuv = fetchgit {
    url = "${chromium_git}/external/libyuv.git";
    rev = "d204db647e591ccf0e2589236ecea90330d65a66";
    sha256 = "00dqa93rxzr72l688ab8mfcpqx6897cxm3yf4qg6cgri7h7x8gms";
  };
  #src/third_party/libsrtp':
  libsrtp = fetchgit {
    url = "${chromium_git}/chromium/deps/libsrtp.git";
    rev = "6446144c7f083552f21cc4e6768e891bcb767574";
    sha256 = "1xq4j9zk5mdpk9wj4mdah53s61nxgbalmz4rwb7zdw0bkvyihpcy";
  };
  #src/third_party/icu':
  icu = fetchgit {
    url = "${chromium_git}/chromium/deps/icu.git";
    rev = "2081ee6abfa118003fd559cb72393f5df561dba7";
    sha256 = "04jph6wqq47002kc4d3pf2vk626il18gskmqfagz5j2svkgwdvn9";
  };
  chromium = fetchgit {
    url = "https://chromium.googlesource.com/chromium/src.git";
    rev = "2c3ffb2355a27c32f45e508ef861416b820c823b";
    sha256 = "03i1acv9hsksbnp8h07az3wbbvpmcqa1kvkr27lv7pzm756xnik6";
  };
  src = fetchsvn {
    url = http://webrtc.googlecode.com/svn/trunk;
    rev = "r8508";
    sha256 = "1i16jdybnffjf94vwv8vax0dn6q7x4icaa531drpacphq0sak6f3";
  };

  #cp -dsr --no-preserve=mode "${source.main}"/* .
  #cp -dsr --no-preserve=mode "${source.sandbox}" sandbox
  #cp -dr "${source.bundled}" third_party
  #chmod -R u+w third_party
  prePatch = ''
    # Hardcode source tree root in all gyp files
    find -iname '*.gyp*' \( -type f -o -type l \) \
      -exec sed -i -e 's|<(DEPTH)|'"$(pwd)"'|g' {} + \
      -exec chmod u+w {} +
  '';

  configurePhase = ''
    HOST_ARCH=x64
    TARGET_ARCH=x64
    export JAVA_HOME="${jdk}"

    export GYP_GENERATORS="ninja"
    export GYP_DEFINES
    GYP_DEFINES="host_arch=$HOST_ARCH target_arch=$TARGET_ARCH"
    GYP_DEFINES="$GYP_DEFINES build_with_libjingle=1"
    GYP_DEFINES="$GYP_DEFINES build_with_chromium=0"
    GYP_DEFINES="$GYP_DEFINES enable_video=0"
    GYP_DEFINES="$GYP_DEFINES enable_protobuf=0"
    GYP_DEFINES="$GYP_DEFINES test_isolation_mode=noop"
    GYP_DEFINES="$GYP_DEFINES include_tests=0"
    GYP_DEFINES="$GYP_DEFINES include_pulse_audio=0"
    GYP_DEFINES="$GYP_DEFINES include_internal_audio_device=0"
    GYP_DEFINES="$GYP_DEFINES include_internal_video_capture=0"
    GYP_DEFINES="$GYP_DEFINES include_internal_video_render=0"
    GYP_DEFINES="$GYP_DEFINES use_x11=0"
    GYP_DEFINES="$GYP_DEFINES use_gnome_keyring=0"

    cp -r $chromium chromium/src
    chmod -R u+w chromium/src

    cp -r $libvpx chromium/src/third_party/libvpx
    cp -r $libyuv chromium/src/third_party/libyuv
    cp -r $libsrtp chromium/src/third_party/libsrtp
    cp -r $icu chromium/src/third_party/icu
    chmod -R u+w chromium/src/third_party

    patchShebangs .
    #sed -i -e 's|/bin/echo|${coreutils}/bin/echo|' chromium/src/build/common.gypi
    sed -i -r \
      -e 's/-f(stack-protector)(-all)?/-fno-\1/' \
      -e 's|/bin/echo|echo|' \
      -e "/python_arch/s/: *'[^']*'/: '""'/" \
      chromium/src/build/common.gypi chromium/src/chrome/chrome_tests.gypi

    python setup_links.py

    echo =================
    #python webrtc/build/gyp_webrtc
    python webrtc/build/gyp_webrtc -f ninja --depth "$(pwd)"
    echo =================
  '';

  buildPhase = ''
    "${ninja}/bin/ninja" -C "${buildPath}"  \
      -j$NIX_BUILD_CORES -l$NIX_BUILD_CORES \
      "${target}"
  '';
}




/*

apt-get install build-essential git golang python subversion default-jre \
 default-jdk pkg-config libgtk2.0-dev libnss3-dev libxss-dev libxtst-dev \
 libdbus-1-dev libdrm-dev gconf-2.0 libgconf2-dev libgnome-keyring-dev \
 libgcrypt-dev libpci-dev libudev-dev libasound2-dev libssl-dev libpulse-dev \
 libglu1-mesa-dev -yy

*/
