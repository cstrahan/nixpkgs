{ stdenv, lib, pkgs, config, makeWrapper, stdenvAdapters, gccApple, fetchFromGitHub, ncurses, gettext,
  pkgconfig, cscope, python, ruby, tcl, perl, luajit,
  env ? (config.vim.env or null)
}:

let
  inherit (stdenvAdapters.overrideGCC stdenv gccApple) mkDerivation;
  shellEscape = x: "'${lib.replaceChars ["'"] [("'\\'" + "'")] x}'";
  hasEnv = env != null && env != { };
  envVars = lib.mapAttrs (n: v: toString v) env;
  wrapArgs = with lib;
    "${concatStringsSep " "
        ((mapAttrsToList (n: v: ''--set ${shellEscape n} ${shellEscape v}'') envVars))}";
  wrappedDrv = mkDerivation rec {
    inherit (unwrappedDrv) name;
    inherit (unwrappedDrv) version;
    buildInputs = [ ruby makeWrapper ];
    unwrapped = unwrappedDrv;
    buildCommand = ''
      # Copy the unwrapped MacVim
      cp -r $unwrapped $out
    '' + lib.optionalString hasEnv ''
      # Wrap with supplied env vars
      chmod -R u+w $out
      wrapProgram $out/bin/mvim ${wrapArgs}
      ruby ${./patch_plist.rb} \
        ${shellEscape (builtins.toXML envVars)} \
        $out/Applications/MacVim.app/Contents/Info.plist
    '';
    inherit (unwrappedDrv) meta;
  };
  unwrappedDrv = mkDerivation rec {
    name = "macvim-${version}";

    version = "7.4-73";

    src = fetchFromGitHub {
      owner = "b4winckler";
      repo = "macvim";
      rev = "snapshot-73";
      sha256 = "0zv82y2wz8b482khkgbl08cnxq3pv5bm37c71wgfa0fzy3h12gcj";
    };

    enableParallelBuilding = true;

    buildInputs = [
      gettext ncurses pkgconfig luajit ruby tcl perl python
    ];

    patches = [ ./macvim.patch ];

    postPatch = ''
      substituteInPlace src/MacVim/mvim --replace "# VIM_APP_DIR=/Applications" "VIM_APP_DIR=$out/Applications"

      # Don't create custom icons.
      substituteInPlace src/MacVim/icons/Makefile --replace '$(MAKE) -C makeicns' ""
      substituteInPlace src/MacVim/icons/make_icons.py --replace "dont_create = False" "dont_create = True"

      # Full path to xcodebuild
      substituteInPlace src/Makefile --replace "xcodebuild" "/usr/bin/xcodebuild"
    '';

    configureFlags = [
        #"--enable-cscope" # TODO: cscope doesn't build on Darwin yet
        "--enable-fail-if-missing"
        "--with-features=huge"
        "--enable-gui=macvim"
        "--enable-multibyte"
        "--enable-nls"
        "--enable-luainterp=yes"
        "--enable-pythoninterp=yes"
        "--enable-perlinterp=yes"
        "--enable-rubyinterp=yes"
        "--enable-tclinterp=yes"
        "--with-luajit"
        "--with-lua-prefix=${luajit}"
        "--with-ruby-command=${ruby}/bin/ruby"
        "--with-tclsh=${tcl}/bin/tclsh"
        "--with-tlib=ncurses"
        "--with-compiledby=Nix"
    ];

    preConfigure = ''
      DEV_DIR=$(/usr/bin/xcode-select -print-path)/Platforms/MacOSX.platform/Developer
      configureFlagsArray+=(
        "--with-developer-dir=$DEV_DIR"
      )
    '';

    postInstall = ''
      ensureDir $out/Applications
      cp -r src/MacVim/build/Release/MacVim.app $out/Applications

      rm $out/bin/{Vimdiff,Vimtutor,Vim,ex,rVim,rview,view}

      cp src/MacVim/mvim $out/bin
      cp src/vimtutor $out/bin

      for prog in "vimdiff" "vi" "vim" "ex" "rvim" "rview" "view"; do
        ln -s mvim $out/bin/$prog
      done
    '';

    meta = with stdenv.lib; {
      description = "Vim - the text editor - for Mac OS X";
      homepage    = https://github.com/b4winckler/macvim;
      maintainers = with maintainers; [ cstrahan ];
      platforms   = platforms.darwin;
    };
  };
in wrappedDrv
