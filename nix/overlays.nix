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

  # patool 4.0.5's test suite asserts libmagic's mime output (e.g. that a
  # .tar.bz2 reports application/x-tar), but our libmagic reports the outer
  # application/x-bzip2, so ~12 mime/tarfile tests fail. This is an
  # environment-dependent test assertion, not a defect in the package. Pulled
  # in transitively as a Python dependency of bottles. Disable the check phase
  # in the Python package set so bottles' copy picks it up too.
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (pyfinal: pyprev: {
      patool = pyprev.patool.overrideAttrs (old: {
        # pytestCheckHook runs in the installCheck phase here, so doCheck has
        # no effect — doInstallCheck is the gate that actually skips it.
        doInstallCheck = false;
      });
    })
  ];

  lutris-unwrapped = prev.lutris-unwrapped.overrideAttrs (old: {
    version = "0.5.22";
    src = prev.fetchFromGitHub {
      owner = "lutris";
      repo = "lutris";
      tag = "v0.5.22";
      hash = "sha256-4mNknvfJQJEPZjQoNdKLQcW4CI93D6BUDPj8LtD940A=";
    };
  });

  # Chromium puts its SingletonSocket under $TMPDIR. Sandboxes with a private
  # /tmp (steam-run, Heroic, Steam) can't reach it there, so links opened from
  # them start a second browser on the locked profile instead of a new tab.
  brave =
    if prev.stdenv.hostPlatform.isLinux then
      prev.brave.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/brave --run 'export TMPDIR="''${XDG_RUNTIME_DIR:-/tmp}"'
        '';
      })
    else
      prev.brave;
}
