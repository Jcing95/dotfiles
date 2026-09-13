# Pin GPU clients to the discrete Navi 31 (03:00.0)
#
# The Granite Ridge iGPU (77:00.0) drives no connected output, yet clients
# default to it while Hyprland composites and scans out on the dGPU — every
# client frame then crosses PCIe before it can be composited, which caps the
# compositor well below the panel's 240Hz.
{ ... }:

{
  environment.variables = {
    DRI_PRIME = "pci-0000_03_00_0";
    MESA_VK_DEVICE_SELECT = "1002:744c!";
  };
}
