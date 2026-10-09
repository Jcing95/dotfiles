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

  wine = pkgs.wineWow64Packages.stagingFull;

  # Wine DPI. The workstation runs XWayland unscaled (force_zero_scaling), so
  # Affinity's chrome is sized purely by this: 144 = 1.5x.
  logPixels = 144;

  affinity = pkgs.writeShellApplication {
    name = "affinity";
    runtimeInputs = [ wine ];
    text = ''
      export WINEPREFIX="${prefix}"
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

      cd "${appDir}"
      exec wine ./Affinity.exe "$@"
    '';
  };

  affinity-setup = pkgs.writeShellApplication {
    name = "affinity-setup";
    runtimeInputs = with pkgs; [ wine winetricks cabextract p7zip unzip curl ];
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
      # Affinity's shell is WPF, which renders through D3D9, and its canvas
      # through D3D11. Both land on wined3d by default, which is slow enough here
      # to make the app unusable (single-digit FPS at this resolution). DXVK puts
      # them on Vulkan instead. d3d12 is left as Wine's builtin vkd3d — Affinity's
      # DXCore probe finds no hardware D3D12 adapter under Wine anyway, and Heroic
      # layers vkd3d-proton on top when the app is launched from there.
      for dll in d3d9 d3d10core d3d11 dxgi; do
        install -m644 "${pkgs.dxvk}/x64/$dll.dll" "$WINEPREFIX/drive_c/windows/system32/$dll.dll"
        install -m644 "${pkgs.dxvk}/x32/$dll.dll" "$WINEPREFIX/drive_c/windows/syswow64/$dll.dll"
        wine reg add 'HKCU\Software\Wine\DllOverrides' /v "$dll" /t REG_SZ /d native /f >/dev/null
      done

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
