# Wine runtime for the Windows applications that have no Linux build (Affinity).
#
# nixpkgs' plain `wine` is an i386-only build, so it cannot host a 64-bit app at
# all; wineWow64Packages is the single-binary new-WoW64 build that runs both
# architectures. Staging because Affinity needs the Vulkan renderer path.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wineWow64Packages.stagingFull
    winetricks
    # winetricks shells out to cabextract for every Microsoft redistributable and
    # to 7z for a few archives; neither is a dependency of the winetricks package.
    cabextract
    p7zip
  ];
}
