{ stdenv, lib, fetchzip, pkgconfig, automake, autoconf, libtool
, glib, dbus_glib, gnome_doc_utils, libdbusmenu_glib, vala
, gtk ? null, gtkVersion ? null, libindicate ? null
, python ? null, pythonPackages ? null, libindicate_gtk2 ? null
}:

let
  suffix = {
    ""  = "";
    "2" = "-gtk2";
    "3" = "-gtk3";
  }."${toString gtkVersion}";
  gtkName = {
    "2" = "gtk";
    "3" = "gtk3";
  }."${toString gtkVersion}";
in
stdenv.mkDerivation rec {
  name =
    if python == null
    then "libindicate${suffix}-${version}"
    else "pyindicate-${version}";

  version = "12.10.1";

  src = fetchzip {
    url = "https://launchpad.net/libindicate/12.10/${version}/+download/libindicate-${version}.tar.gz";
    sha256 = "1rgh87bwkppg9d9qi9qacsr9izv7fpf23br6ddm44d0a8rvkhqcv";
  };

  postPatch = lib.optionalString (python != null) ''
    sed  -i configure.ac \
      -e 's@^PYGTK_CODEGEN=.*@PYGTK_CODEGEN=${pythonPackages.pygtk}/bin/pygtk-codegen-2.0@'
    substituteInPlace configure.ac \
      --replace '-lpyglib-2.0-python$PYTHON_VERSION' \
                '-lpyglib-2.0-python'
  '';

  preConfigure = ''
    automake --gnu --add-missing --copy
    autoreconf --install --force --verbose
  '' + lib.optionalString (python == null) ''
    configureFlagsArray+=(--disable-python)
  '' + lib.optionalString (gtkVersion == null) ''
    configureFlagsArray+=(--disable-gtk)
  '' + lib.optionalString (gtkVersion == 2) ''
    configureFlagsArray+=(--with-gtk=2)
  '' + lib.optionalString (gtkVersion == 3) ''
    configureFlagsArray+=(--with-gtk=3)
  '';

  buildInputs = [
    autoconf automake libtool
    pkgconfig glib dbus_glib gnome_doc_utils libdbusmenu_glib vala
  ] ++ lib.optionals (gtkVersion != null) [
    gtk libindicate
  ] ++ lib.optionals (python != null) [
    libindicate_gtk2
  ];

  propagatedBuildInputs = lib.optionals (gtkVersion != null) [
  ] ++ lib.optionals (python != null) [
    python pythonPackages.pygtk pythonPackages.pygobject
  ];

  postInstall = lib.optionalString (gtkVersion != null) ''
    sed -i $out/lib/libindicate-${gtkName}.la \
      -e 's@\S\+/libindicate.la@${libindicate}/lib/libindicate.la@'

    rm -vr $out/include/libindicate-*
    rm -vr $out/lib/girepository-*/Indicate-*
    rm -vr $out/lib/libindicate.*
    rm -vr $out/lib/pkgconfig/indicate-0.7.pc
    rm -vr $out/share/doc
    rm -vr $out/share/gtk-doc
    rm -vr $out/share/gir-*/Indicate-*
    rm -vr $out/share/vala/vapi/Indicate-*
  '' + lib.optionalString (python != null) ''
    sed -i $out/lib/libindicate-${gtkName}.la \
      -e 's@\S\+/libindicate.la@${libindicate}/lib/libindicate.la@' \
      -e 's@\S\+/libindicate-gtk.la@${libindicate_gtk2}/lib/libindicate.la@' \
      -e 's@-L\S\+/libindicate/.libs/@${libindicate}/lib@' \
      -e 's@-L\S\+/libindicate-gtk/.libs@${libindicate_gtk2}/lib@'

    rm -vr $out/lib/gdk-pixbuf-loaders-2.0
    rm -vr $out/lib/girepository-1.0
    rm -vr $out/lib/libindicate-*
    rm -vr $out/lib/pkgconfig
    rm -vr $out/share/gir-*
    rm -vr $out/share/vala

    so=$out/${python.sitePackages}/indicate/_indicate.so
    echo "patching $so"

    patchelf --set-rpath "$(patchelf --print-rpath $so):${libindicate_gtk2}/lib" $so
    patchelf --shrink-rpath $so
  '';

  meta = with lib; {
    description = "Small library for applications to raise "flags" on DBus for other components of the desktop to pick up and visualize";
    homepage = "https://launchpad.net/libindicate/";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}
