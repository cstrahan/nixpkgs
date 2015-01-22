# The standard set of gems in nixpkgs including potential fixes.
#
# The gemset is derived from two points of entry:
# - An attrset describing a gem, including version, source and dependencies
#   This is just meta data, most probably automatically generated by a tool
#   like Bundix (https://github.com/aflatter/bundix).
#   {
#     name = "bundler";
#     version = "1.6.5";
#     sha256 = "1s4x0f5by9xs2y24jk6krq5ky7ffkzmxgr4z1nhdykdmpsi2zd0l";
#     dependencies = [ "rake" ];
#   }
# - An optional derivation that may override how the gem is built. For popular
#   gems that don't behave correctly, fixes are already provided in the form of
#   derivations.
#
# This seperates "what to build" (the exact gem versions) from "how to build"
# (to make gems behave if necessary).

{ lib, fetchurl, writeScript, ruby, libxml2, libxslt, python, stdenv, which
, libiconv, postgresql, v8, v8_3_16_14, clang, sqlite, zlib, imagemagick, pkgconfig
, ncurses, xapian, gpgme, utillinux, fetchpatch
}:

let
  v8 = v8_3_16_14;

in

{
  gpgme = attrs: {
    buildInputs = [ gpgme ];
  };

  libv8 = attrs: {
    buildInputs = [ which v8 python ];
    buildFlags = [
      "--with-system-v8=true"
    ];
    patches = [
      # see: https://github.com/cowboyd/libv8/pull/161
      (fetchpatch {
        url = https://github.com/cstrahan/libv8/commit/c79378bf346d4ed2429af36d745d17c478ffbe96.patch;
        sha256 = "1l6572cmigc22g249jj8h0xlbig88mj43kdqdbimhw2pmpv3q0rs";
      })
    ];
  };

  ncursesw = attrs: {
    buildInputs = [ ncurses ];
    buildFlags = [
      "--with-cflags=-I${ncurses}/include"
      "--with-ldflags=-L${ncurses}/lib"
    ];
  };

  nokogiri = attrs: {
    buildFlags = [
      "--use-system-libraries"
      "--with-zlib-dir=${zlib}"
      "--with-xml2-lib=${libxml2}/lib"
      "--with-xml2-include=${libxml2}/include/libxml2"
      "--with-xslt-lib=${libxslt}/lib"
      "--with-xslt-include=${libxslt}/include"
      "--with-exslt-lib=${libxslt}/lib"
      "--with-exslt-include=${libxslt}/include"
    ] ++ lib.optional stdenv.isDarwin "--with-iconv-dir=${libiconv}";
  };

  pg = attrs: {
    buildFlags = [
      "--with-pg-config=${postgresql}/bin/pg_config"
    ];
  };

  rmagick = attrs: {
    buildInputs = [ imagemagick pkgconfig ];
  };

  sqlite3 = attrs: {
    buildFlags = [
      "--with-sqlite3-include=${sqlite}/include"
      "--with-sqlite3-lib=${sqlite}/lib"
    ];
  };

  sup = attrs: {
    # prevent sup from trying to dynamically install `xapian-ruby`.
    postPatch = ''
      cp ${./mkrf_conf_xapian.rb} ext/mkrf_conf_xapian.rb

      substituteInPlace lib/sup/crypto.rb \
        --replace 'which gpg2' \
                  '${which}/bin/which gpg2'
    '';
  };

  therubyracer = attrs: {
    buildFlags = [
      "--with-v8-dir=${v8}"
      "--with-v8-include=${v8}/include"
      "--with-v8-lib=${v8}/lib"
    ];
  };

  xapian-ruby = attrs: {
    # use the system xapian
    buildInputs = [ xapian pkgconfig zlib ];
    postPatch = ''
      cp ${./xapian-Rakefile} Rakefile
    '';
    preInstall = ''
      export XAPIAN_CONFIG=${xapian}/bin/xapian-config
    '';
  };
}
