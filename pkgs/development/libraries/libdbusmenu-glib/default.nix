{ stdenv, lib, fetchzip, pkgconfig
, glib, intltool, dbus_glib, gnome_doc_utils, atk, json_glib, libxslt
, gtk, gtkVersion ? null, libdbusmenu_glib ? null
}:

let
  suffix = {
    ""  = "glib";
    "2" = "gtk2";
    "3" = "gtk3";
  }."${toString gtkVersion}";
  gtkName = {
    "2" = "gtk";
    "3" = "gtk3";
  }."${toString gtkVersion}";
in
stdenv.mkDerivation rec {
  name = "libdbusmenu-${suffix}-${version}";

  version = "12.10.2";

  src = fetchzip {
    url = "https://launchpad.net/libdbusmenu/12.10/${version}/+download/libdbusmenu-${version}.tar.gz";
    sha256 = "137dp1c7sf9qgm5v9f8qimcshvpj57jhfns4k44amghc1ypsb5ja";
  };

  preConfigure = ''
    NIX_CFLAGS_COMPILE="-Wno-error=deprecated-declarations"
  '' + lib.optionalString (gtkVersion == null) ''
    configureFlagsArray+=(--disable-gtk --disable-dumper --disable-tests)
    export HAVE_VALGRIND_TRUE='#'
    export HAVE_VALGRIND_FALSE=
  '' + lib.optionalString (gtkVersion == 2) ''
    configureFlagsArray+=(--with-gtk=2)
  '' + lib.optionalString (gtkVersion == 3) ''
    configureFlagsArray+=(--with-gtk=3 --disable-dumper --disable-tests)
    export HAVE_VALGRIND_TRUE='#'
    export HAVE_VALGRIND_FALSE=
  '';

  buildInputs = [
    libxslt json_glib pkgconfig glib dbus_glib intltool gnome_doc_utils atk
  ] ++ lib.optionals (gtkVersion != null) [
    gtk libdbusmenu_glib
  ];

  postInstall = lib.optionalString (gtkVersion != null) ''
    sed -e 's@\S\+/libdbusmenu-glib.la@${libdbusmenu_glib}/lib/libdbusmenu-glib.la@' -i $out/lib/libdbusmenu-${gtkName}.la

    rm -vr $out/include/libdbusmenu-glib*
    rm -v  $out/lib/libdbusmenu-glib*
    rm -v  $out/lib/libdbusmenu-jsonloader*
    rm -v  $out/lib/pkgconfig/dbusmenu-{glib,jsonloader}*.pc
    rm -v  $out/libexec/dbusmenu-{bench,testapp}
    rm -vr $out/share/doc
    rm -vr $out/share/gir-*/Dbusmenu-*.gir
    rm -vr $out/share/gtk-doc/html/libdbusmenu-glib
    rm -vr $out/share/libdbusmenu

    mv -v $out/share/gtk-doc/html/libdbusmenu-gtk{,${toString gtkVersion}}
  '';

  meta = with lib; {
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}
