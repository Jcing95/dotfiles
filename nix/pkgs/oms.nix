{ lib, buildGoModule, stdenv, src }:

buildGoModule {
  pname = "oms";
  version = src.shortRev or "unstable";

  inherit src;
  subPackages = [ "cli" ];

  # Relax Go version requirement when nixpkgs is slightly behind
  preBuild = ''
    substituteInPlace go.mod --replace-fail "go 1.26.2" "go 1.26.1"
  '';

  vendorHash = "sha256-7Pm24VHj9UgcK4pxEysfqeKOAMXzKKbnxMCf4ST4D1g=";

  ldflags = let pkg = "github.com/codesphere-cloud/oms/internal/version"; in [
    "-X ${pkg}.version=${src.shortRev or "unstable"}"
    "-X ${pkg}.commit=${src.rev or "unknown"}"
    "-X ${pkg}.os=${stdenv.hostPlatform.parsed.kernel.name}"
    "-X ${pkg}.arch=${stdenv.hostPlatform.parsed.cpu.name}"
    "-X ${pkg}.date=${src.lastModifiedDate or "unknown"}"
  ];

  postInstall = ''
    mv $out/bin/cli $out/bin/oms
  '';

  meta = with lib; {
    description = "Codesphere OMS CLI";
    homepage = "https://github.com/codesphere-cloud/oms";
    license = licenses.asl20;
  };
}
