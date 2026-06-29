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

  # cantarell-fonts 0.311 fails to build: afdko 5's otfautohint crashes while
  # autohinting the variable font (NixOS/nixpkgs#535887, no upstream fix yet).
  # Autohinting is cosmetic polish that runs after the (already-valid) font is
  # saved, so neutralise the call to let the build produce the un-hinted font.
  # Pulled in transitively (Steam FHS env, system fonts). Remove once #535887 lands.
  cantarell-fonts = prev.cantarell-fonts.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace scripts/make-variable-font.py \
        --replace-fail "subprocess.check_call(" "(lambda *a, **k: None)("
    '';
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
