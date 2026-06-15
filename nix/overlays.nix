# Overlays for packages that need newer versions than nixpkgs provides.
# Add overrides here when nixpkgs-unstable lags behind upstream releases.
final: prev: {
  openldap = prev.openldap.overrideAttrs (old: {
    doCheck = false;
  });

  # helm 4.2.0's nixpkgs derivation has a Darwin-only preCheck that runs
  # substituteInPlace on cmd/helm/*_test.go, but helm 4.x moved those files
  # to pkg/cmd/. The --replace-fail aborts the build on aarch64-darwin.
  # Skip the test phase until nixpkgs fixes the paths.
  kubernetes-helm = prev.kubernetes-helm.overrideAttrs (old: {
    doCheck = false;
  });

  lutris-unwrapped = prev.lutris-unwrapped.overrideAttrs (old: {
    version = "0.5.22";
    src = prev.fetchFromGitHub {
      owner = "lutris";
      repo = "lutris";
      tag = "v0.5.22";
      hash = "sha256-4mNknvfJQJEPZjQoNdKLQcW4CI93D6BUDPj8LtD940A=";
    };
  });
}
