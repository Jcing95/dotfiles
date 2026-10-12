# Pin GPU clients to the discrete Navi 31 (03:00.0)
#
# The Granite Ridge iGPU (77:00.0) drives no output but is boot_vga, so
# aquamarine makes it Hyprland's primary renderer. Chromium and Xwayland follow
# the compositor's main device and render there too, which saturates the iGPU
# and pushes every frame across PCIe to the dGPU for scanout.
#
# The iGPU stays listed last as a fallback; aquamarine skips missing entries.
# Symlinks because card numbering isn't stable and by-path names contain
# colons, AQ_DRM_DEVICES' separator.
{ ... }:

{
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:03:00.0", SYMLINK+="dri/dgpu"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:77:00.0", SYMLINK+="dri/igpu"
  '';

  environment.variables = {
    AQ_DRM_DEVICES = "/dev/dri/dgpu:/dev/dri/igpu";
    DRI_PRIME = "pci-0000_03_00_0";
    MESA_VK_DEVICE_SELECT = "1002:744c!";
  };
}
