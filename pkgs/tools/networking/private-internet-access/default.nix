{ stdenv, lib, fetchzip, fetchurl, pkgconfig, ruby }:

# This isn't anywhere near finished . . .

stdenv.mkDerivation rec {
  name = "private-internet-access-${version}";
  version = "1.0.0";
  src = fetchurl {
    name = "installer_linux.tar.gz";
    url = "https://www.privateinternetaccess.com/installer/download_previous_installer/U2FsdGVkX19Gg_iqvQf39A6EpNMtdPnu3fVw8KSRyI9BUnxNvRdsEzO8fGtsHne-,jVciTB3shfr6ubYFOHJDy4wSHoY";
    sha256 = "0nasgwj7ym2zmfnylz2x7m8w88wkajbc8a36gvks9l83fzw9kx3x";
  };
  buildInputs = [ ruby ];
  unpackPhase = ''
    runHook preUnpack
    tar -zxvf $src
    runHook postUnpack
  '';
  postUnpack = ''
    sed -e '1,/^exit$/d' ./installer_linux.sh | tar xzf -
    mkdir unpacked
    ruby <<"EOF"
      require 'zlib'
      require 'fileutils'

      install_path = "unpacked"

      data = File.binread("installer_linux/run.rb")
      data.sub! /\A.+?__END__\n/m, ""

      data.sub! /\A([^\n]+\n)/, ""
      sep = $1

      data.split(sep).each_slice(3) do |filename, mode, compressed_data|
        path = File.join(install_path, filename)
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.rm_rf(path)
        File.open(path, 'wb') {|f| f.write Zlib::Inflate.inflate(compressed_data) }
        File.chmod(mode.to_i, path)
      end
      Dir[File.join(install_path, 'pia_tray', 'modules', 'tinetwork', '*', 'tinetworkmodule.js')].each do |f|
        File.delete(f) rescue nil
      end
    EOF
  '';
  installPhase = ''
    cp -r unpacked $out
  '';
  meta = with lib; {
    description = "...";
    homepage = "...";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}
