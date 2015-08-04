{ stdenv, lib, fetchFromGitHub, pkgconfig, itstool, automake, autoconf ,
, intltool, yelp_tools, vala, libxml2, freetype, fontconfig, glib, json_glib,
, cairo, gtk3, pango, libgee, gucharmap, sqlite
, gnome3, hicolor_icon_theme, makeWrapper
, file-roller # TODO: remove
}:

stdenv.mkDerivation rec {
  name = "font-manager-${version}";
  version = "0.7.2";
  src = fetchFromGitHub {
    owner = "FontManager";
    repo = "master";
    rev = version;
    sha256 = "0b4a3mhvvf6q6bk77j40prikaz32rz86brwyyp0wychlx6n7qk8j";
  };
  buildInputs = [
    pkgconfig automake autoconf intltool yelp_tools itstool
    vala libxml2 freetype fontconfig glib
    json_glib cairo gtk3 pango libgee gucharmap sqlite
    file-roller # TODO: remove
    makeWrapper
    gnome3.defaultIconTheme
    hicolor_icon_theme
  ];
  postFixup = ''
    schema=$out/share/gsettings-schemas/font-manager-*
    wrapProgram "$out/bin/font-manager" \
      --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH" \
      --prefix XDG_DATA_DIRS : "$XDG_ICON_DIRS:${gnome3.gnome_themes_standard}/share:$schema:$GSETTINGS_SCHEMAS_PATH"
  '';
  meta = with lib; {
    description = "Simple font management application for GTK+ Desktop Environments";
    homepage = "http://fontmanager.github.io/";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}
