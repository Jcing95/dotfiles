{ lib, stdenv, fetchurl }:

let
  version = "1.33.0";
in
stdenv.mkDerivation {
  pname = "oms";
  inherit version;

  src = fetchurl {
    url = "https://github.com/codesphere-cloud/oms/releases/download/v${version}/oms_${version}_darwin_arm64";
    sha256 = "cded5b0358a53943a5e131f0dc46fd11d397e8e07bd1837de275d899d18ea241";
  };

  dontUnpack = true;

  installPhase = ''
    install -D -m 755 $src $out/bin/oms
  '';

  meta = with lib; {
    description = "Codesphere OMS CLI";
    homepage = "https://github.com/codesphere-cloud/oms";
    platforms = [ "aarch64-darwin" ];
  };
}
