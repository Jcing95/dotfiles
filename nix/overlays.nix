# Overlays for packages that need newer versions than nixpkgs provides.
# Add overrides here when nixpkgs-unstable lags behind upstream releases.
final: prev: {
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
