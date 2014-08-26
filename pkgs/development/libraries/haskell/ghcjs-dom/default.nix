{ cabal, fetchgit, ghc, mtl
, buildType ? if ghc.ghc.pname or null == "ghcjs" then "jsffi" else "webkit"
, ghcjsBase ? null # jsffi dependencies
, glib ? null, transformers ? null, gtk ? null, webkit ? null # webkit dependencies
}:

cabal.mkDerivation (self: {
  pname = "ghcjs-dom";
  version = "0.1.1.0";
  sha256 = "0ywxkp13n78skbcr0d1m5mgz23xds27sdfxswfc9zjcsb513w3gg";
  #buildDepends = [ ghcjsBase mtl text ];
  buildDepends = [ mtl ] ++ (if buildType == "jsffi" then [ ghcjsBase ] else if buildType == "webkit" then [ glib transformers gtk webkit ] else throw "unrecognized buildType");
  configureFlags = if buildType == "jsffi" then [ ] else if buildType == "webkit" then [ "-f-ghcjs" "-fwebkit" "-f-gtk3" ] else throw "unrecognized buildType";
  meta = {
    description = "DOM library that supports both GHCJS and WebKitGTK";
    license = self.stdenv.lib.licenses.mit;
    platforms = self.ghc.meta.platforms;
  };
})
