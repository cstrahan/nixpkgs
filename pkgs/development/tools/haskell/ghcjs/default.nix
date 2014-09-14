{ nodejs, cabal, filepath, HTTP, HUnit, mtl, network, QuickCheck, random, stm
, testFramework, testFrameworkHunit, testFrameworkQuickcheck2, time
, zlib, aeson, attoparsec, bzlib, dataDefault, ghcPaths, hashable
, haskellSrcExts, haskellSrcMeta, lens, optparseApplicative
, parallel, safe, shelly, split, stringsearch, syb, systemFileio
, systemFilepath, tar, terminfo, textBinary, unorderedContainers
, vector, wlPprintText, yaml, fetchgit, Cabal, CabalGhcjs, cabalInstall
, regexPosix, alex, happy, git, gnumake, gcc, autoconf, patch
, automake, libtool, cabalInstallGhcjs, gmp, base16Bytestring
, cryptohash, executablePath, transformersCompat
, haddockApi, hspec, xhtml, primitive, cacert, pkgs, ghc
}:
let
  ghcjsBoot = fetchgit {
    url = git://github.com/ghcjs/ghcjs-boot.git;
    rev = "f5e57f9d4d8241a78ebdbdb34262921782a27e1a";
    sha256 = "1688zan65k36cv4hbzkx48kcmpkn8pswdacl6anrb6079wb06v5q";
  };
  shims = fetchgit {
    url = git://github.com/ghcjs/shims.git;
    rev = "dc5bb54778f3dbba4b463f4f7df5f830f14d1cb6";
    sha256 = "1kn9czzz8n16k4dbjc2q75yrpwz3w31sfhl6380v2d87vxwjivzw";
  };
  ghcjsPrim = cabal.mkDerivation (self: {
    pname = "ghcjs-prim";
    version = "0.1.0.0";
    src = fetchgit {
      url = git://github.com/ghcjs/ghcjs-prim.git;
      rev = "659d6ceb45b1b8ef526c7451d90afff80d76e2f5";
      sha256 = "55b64d93cdc8220042a35ea12f8c53e82f78b51bc0f87ddd12300ad56e4b7ba7";
    };
    buildDepends = [ primitive ];
  });
in cabal.mkDerivation (self: rec {
  pname = "ghcjs";
  # the version reflects the binary names, e.g. ghcjs
  version = "0.1.0-7.8.3";
  src = fetchgit {
    url = git://github.com/ghcjs/ghcjs.git;
    rev = "346627db9991059b6d50fe04fe10efde12837676";
    sha256 = "1h2cvnprlf8328b68v3p05nk92ksywx7g5isz2rrb8izkhvax9nl";
  };
  isLibrary = true;
  isExecutable = true;
  jailbreak = true;
  noHaddock = true;
  buildDepends = [
    filepath HTTP mtl network random stm time zlib aeson attoparsec
    bzlib dataDefault ghcPaths hashable haskellSrcExts haskellSrcMeta
    lens optparseApplicative parallel safe shelly split
    stringsearch syb systemFileio systemFilepath tar terminfo textBinary
    unorderedContainers vector wlPprintText yaml
    alex happy git gnumake gcc autoconf automake libtool patch gmp
    base16Bytestring cryptohash executablePath
    transformersCompat QuickCheck hspec xhtml
    regexPosix haddockApi
  ];
  buildTools = [ nodejs ghcjsPrim ];
  testDepends = [
    HUnit testFramework testFrameworkHunit
  ];
  patches = [ ./ghcjs.patch ];
  postPatch = ''
    substituteInPlace src/Compiler/Info.hs --replace "@PREFIX@" "$out"
    substituteInPlace src-bin/Boot.hs --replace "@PREFIX@" "$out" \
                                      --replace "@COMPILER@" "ghcjs-0.1.0-7.8.3"
  '';
  postInstall = ''
    local topDir=$out/share/ghcjs
    mkdir -p $topDir

    cp -r ${ghcjsBoot} $topDir/ghcjs-boot
    chmod -R u+w $topDir/ghcjs-boot

    cp -r ${shims} $topDir/shims
    chmod -R u+w $topDir/shims

    PATH=$out/bin:${CabalGhcjs}/bin:$PATH LD_LIBRARY_PATH=${gmp}/lib:${gcc.gcc}/lib64:$LD_LIBRARY_PATH \
      env -u GHC_PACKAGE_PATH $out/bin/ghcjs-boot \
        --dev \
        --with-cabal ${cabalInstallGhcjs}/bin/cabal-js \
        --with-gmp-includes ${gmp}/include \
        --with-gmp-libraries ${gmp}/lib
  '';
  meta = {
    homepage = "https://github.com/ghcjs/ghcjs";
    description = "GHCJS is a Haskell to JavaScript compiler that uses the GHC API";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.jwiegley ];
  };
})
