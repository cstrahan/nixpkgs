{ runCommand, fetchurl }:

let
  exe = fetchurl {
    name = "NuGet.exe";
    url = "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=nuget&DownloadId=1441482&FileTime=130718730855530000&Build=20959";
    sha256 = "0ffzydrphaxsmxckcn5msx489ra0hb28h2885g11gwa1msxma13f";
  };

in runCommand "nuget-bootstrap" { } ''
  mkdir -p $out/bin
  cp ${exe} $out/bin/NuGet.exe
''
