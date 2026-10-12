# Affinity (Canva) under Wine.
#
# Affinity ships no Linux build and only an MSIX/EXE for Windows, so the app
# itself lives in a Wine prefix under $HOME and is installed imperatively by
# `affinity-setup`. Only the launcher, the sign-in handler and the setup recipe
# are declarative here.
{ config, pkgs, lib, ... }:

let
  # Heroic's default prefix root, so the suite also shows up as a sideloaded app
  # there instead of needing a second prefix.
  prefix = "${config.home.homeDirectory}/Games/Heroic/Prefixes/default/Affinity";
  appDir = "${prefix}/drive_c/Program Files/Affinity/Affinity";

  # Prefix construction only. Running Affinity needs ElementalWarrior's build
  # below, but winetricks is far easier to drive against a normal nixpkgs wine,
  # and both are 11.18 so they agree on the prefix.
  wine = pkgs.wineWow64Packages.stagingFull;

  # Libraries the prebuilt wine's unix modules dlopen; handed to it through
  # nix-ld, which core.nix already enables.
  wineLibs = lib.makeLibraryPath (with pkgs; [
    libx11 libxext libxrandr libxi libxcursor
    libxinerama libxcomposite libxfixes libxrender libxcb
    libxkbcommon freetype fontconfig libGL vulkan-loader mesa libdrm
    alsa-lib libpulseaudio openal gnutls libgcrypt SDL2 libusb1 systemd
    krb5 wayland zlib ocl-icd libpcap pcsclite glib gtk3 cups
    gst_all_1.gstreamer gst_all_1.gst-plugins-base
  ]);

  # Stock Wine mis-handles Affinity's in-app drag and drop — its OLE drag loop
  # dispatches mouse input instead of handling it — and gets panel re-docking and
  # modal dialog stacking wrong. ElementalWarrior's build carries the Affinity
  # patch set for exactly those. Kept in Heroic's tools directory so Heroic's
  # own launch path finds it without extra configuration.
  ewWine = rec {
    version = "11.18";
    release = "11.18-r1";
    sha256 = "c325bf804407abcf8070d02066b5be00680b0339e796a6583b4a1d2dae934853";
    dir = "${config.home.homeDirectory}/.config/heroic/tools/wine/ElementalWarrior-wine-${version}";
    url = "https://github.com/jfacemyer/Affinity-Wine-Builder/releases/download/${release}/ElementalWarrior-wine-${version}.tar.xz";
  };

  # Wine DPI. The workstation runs XWayland unscaled (force_zero_scaling), so
  # Affinity's chrome is sized purely by this: 192 = 2x.
  logPixels = 192;

  affinity = pkgs.writeShellApplication {
    name = "affinity";
    runtimeInputs = [ ];
    text = ''
      export WINEPREFIX="${prefix}"
      # ElementalWarrior's wine is a prebuilt FHS binary, so it needs its loader
      # and libraries supplied — via nix-ld rather than an FHS sandbox. A sandbox
      # (steam-run) gives every launch its own mount namespace, so wine derives a
      # different server directory from the prefix's device id each time and each
      # launch gets a private wineserver. That breaks Affinity's single-instance
      # IPC, and with it the Canva sign-in callback, which is handed to the
      # running instance as an argv URL.
      export NIX_LD="''${NIX_LD:-/run/current-system/sw/share/nix-ld/lib/ld.so}"
      export NIX_LD_LIBRARY_PATH="${wineLibs}"
      export WINEDEBUG="''${WINEDEBUG:--all}"
      export WINEFSYNC=1
      # winemenubuilder would rewrite ~/.local/share/applications on every start,
      # fighting the entries home-manager puts there.
      export WINEDLLOVERRIDES="winemenubuilder.exe=d"

      # -f, not -x: the exe comes out of the MSIX zip without an executable bit,
      # which Wine does not need to run a PE binary.
      if [ ! -f "${appDir}/Affinity.exe" ]; then
        echo "affinity: no installation in ${prefix} — run affinity-setup first" >&2
        exit 1
      fi
      if [ ! -x "${ewWine.dir}/bin/wine" ]; then
        echo "affinity: patched wine missing from ${ewWine.dir} — run affinity-setup first" >&2
        exit 1
      fi

      cd "${appDir}"
      exec "${ewWine.dir}/bin/wine" ./Affinity.exe "$@"
    '';
  };

  affinity-setup = pkgs.writeShellApplication {
    name = "affinity-setup";
    runtimeInputs = with pkgs; [ wine winetricks cabextract p7zip unzip curl gnutar xz ];
    text = ''
      set -euo pipefail

      installer="''${1:-}"
      if [ -z "$installer" ]; then
        echo "usage: affinity-setup <Affinity x64.msix | affinity-setup.exe>" >&2
        exit 2
      fi

      export WINEPREFIX="${prefix}"
      export WINEDEBUG=-all
      export W_OPT_UNATTENDED=1
      # winetricks probes the wine binary's ELF header to pick wine vs wine64; the
      # new-WoW64 build is a single binary behind a shell wrapper, so the probe
      # fails and it ends up calling an empty $WINE64 for every env expansion.
      export WINE=wine WINE64=wine

      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT

      echo ">>> wine prefix"
      mkdir -p "$WINEPREFIX"
      wine wineboot -u

      echo ">>> interface scale"
      wine reg add 'HKCU\Control Panel\Desktop' /v LogPixels /t REG_DWORD /d ${toString logPixels} /f

      echo ">>> windows dependencies"
      winetricks -q remove_mono
      winetricks -q win11 renderer=vulkan
      winetricks -q vcrun2022
      winetricks -q corefonts tahoma
      winetricks -q dotnet48
      # A fresh prefix antialiases fonts in greyscale, which reads as soft next
      # to every subpixel-rendered native app on the same screen.
      winetricks -q fontsmooth=rgb

      echo ">>> DXVK"
      # Affinity's canvas renders through D3D11, which on wined3d is slow enough
      # here to make the app unusable (single-digit FPS at this resolution). DXVK
      # puts it on Vulkan instead. d3d12 is left as Wine's builtin vkd3d — Affinity's
      # DXCore probe finds no hardware D3D12 adapter under Wine anyway, and Heroic
      # layers vkd3d-proton on top when the app is launched from there.
      for dll in d3d9 d3d10core d3d11 dxgi; do
        install -m644 "${pkgs.dxvk}/x64/$dll.dll" "$WINEPREFIX/drive_c/windows/system32/$dll.dll"
        install -m644 "${pkgs.dxvk}/x32/$dll.dll" "$WINEPREFIX/drive_c/windows/syswow64/$dll.dll"
        wine reg add 'HKCU\Software\Wine\DllOverrides' /v "$dll" /t REG_SZ /d native /f >/dev/null
      done
      # The WPF shell goes software. Hardware WPF under XWayland loses the first
      # frame of new popups and panels, leaving them black (DXVK, wined3d Vulkan)
      # or white (wined3d GL) apart from controls that later repaint.
      wine reg add 'HKCU\Software\Microsoft\Avalon.Graphics' /v DisableHWAcceleration /t REG_DWORD /d 1 /f

      echo ">>> WinMetadata"
      # WinRT metadata is not part of Wine; Affinity's CLR needs it to JIT the
      # methods behind the Canva sign-in callback.
      if [ ! -d "$WINEPREFIX/drive_c/windows/system32/WinMetadata" ]; then
        curl -fL --retry 3 -o "$work/WinMetadata.zip" \
          https://archive.org/download/win-metadata/WinMetadata.zip
        unzip -q -o "$work/WinMetadata.zip" -d "$WINEPREFIX/drive_c/windows/system32/"
      fi

      echo ">>> WinRT facades"
      # Shipped only with the OS-integrated .NET on Windows 10, not by the 4.8
      # redistributable, so they have to be lifted out of its KB cab by hand.
      gac="$WINEPREFIX/drive_c/windows/Microsoft.NET/assembly/GAC_MSIL"
      if [ ! -f "$gac/System.Runtime.WindowsRuntime/v4.0_4.0.0.0__b77a5c561934e089/System.Runtime.WindowsRuntime.dll" ]; then
        ndp="$HOME/.cache/winetricks/dotnet48/ndp48-x86-x64-allos-enu.exe"
        7z e -y -o"$work" "$ndp" x64-Windows10.0-KB4486153-x64.cab >/dev/null
        cabextract -q -d "$work/cab" \
          -F 'msil_system.runtime.windowsruntime*/*.dll' "$work/x64-Windows10.0-KB4486153-x64.cab"
        while read -r dll; do
          case "$dll" in
            *ui.xaml.dll) name=System.Runtime.WindowsRuntime.UI.Xaml ;;
            *)            name=System.Runtime.WindowsRuntime ;;
          esac
          install -Dm644 "$dll" "$gac/$name/v4.0_4.0.0.0__b77a5c561934e089/$name.dll"
        done < <(find "$work/cab" -name '*.dll')
      fi

      echo ">>> WebView2 runtime"
      # Affinity v3 aborts at startup without it ("Couldn't find a compatible
      # Webview2 Runtime installation to host WebViews").
      if [ ! -d "$WINEPREFIX/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application" ]; then
        curl -fL --retry 3 -o "$work/MicrosoftEdgeWebview2Setup.exe" \
          'https://go.microsoft.com/fwlink/p/?LinkId=2124703'
        wine "$work/MicrosoftEdgeWebview2Setup.exe" /silent /install
        wineserver -k
      fi

      echo ">>> Affinity"
      case "$installer" in
        *.msix)
          # An MSIX cannot be installed under Wine, but it is a zip whose App/
          # tree is exactly what the MSI route unpacks into Program Files.
          # Replaced wholesale so an upgrade leaves no DLLs of the old version
          # behind; nothing user-owned lives here, settings are under AppData.
          unzip -q -o "$installer" 'App/*' 'Package/*' resources.pri AppxManifest.xml -d "$work/msix"
          rm -rf "${appDir}"
          mkdir -p "${appDir}/Package"
          cp -a "$work/msix/App/." "${appDir}/"
          cp -a "$work/msix/resources.pri" "$work/msix/AppxManifest.xml" "${appDir}/"
          cp -a "$work/msix/Package/." "${appDir}/Package/"
          ;;
        *)
          wine "$installer"
          ;;
      esac

      echo ">>> patched wine"
      if [ ! -x "${ewWine.dir}/bin/wine" ]; then
        curl -fL --retry 3 -o "$work/ew-wine.tar.xz" "${ewWine.url}"
        echo "${ewWine.sha256}  $work/ew-wine.tar.xz" | sha256sum -c -
        mkdir -p "$(dirname "${ewWine.dir}")"
        tar -xf "$work/ew-wine.tar.xz" -C "$(dirname "${ewWine.dir}")"
      fi

      echo ">>> desktop integration"
      icon="${appDir}/Package/AppLogo.scale-400.png"
      if [ -f "$icon" ]; then
        install -Dm644 "$icon" "$HOME/.local/share/icons/hicolor/256x256/apps/affinity.png"
      fi
      echo ">>> done — launch with: affinity"
    '';
  };
in
{
  home.packages = [ affinity affinity-setup ];

  xdg.desktopEntries = {
    affinity = {
      name = "Affinity";
      comment = "Affinity photo, design and publishing suite";
      exec = "affinity %F";
      icon = "affinity";
      terminal = false;
      categories = [ "Graphics" "2DGraphics" "RasterGraphics" "VectorGraphics" ];
      mimeType = [
        "application/x-affinity-photo"
        "application/x-affinity-designer"
        "application/x-affinity-publisher"
      ];
    };

    affinity-url-handler = {
      name = "Affinity sign-in handler";
      exec = "affinity %u";
      noDisplay = true;
      terminal = false;
      mimeType = [ "x-scheme-handler/affinity" ];
    };
  };

  # Canva's sign-in callback comes back as an affinity:// URL and has to reach
  # Affinity.exe as a plain argument — Wine's own handler routes it through
  # `wine start`, which truncates past ~300 characters while the callback runs to
  # roughly 1700. Set imperatively rather than through xdg.mimeApps, which would
  # take ownership of every other association in mimeapps.list.
  home.activation.affinityUrlScheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.xdg-utils}/bin/xdg-mime default \
      affinity-url-handler.desktop x-scheme-handler/affinity
  '';
}
