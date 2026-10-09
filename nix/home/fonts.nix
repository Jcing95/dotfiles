# Fonts that are not packaged in nixpkgs.
#
# Everything under dotfiles/fonts is installed — drop a .ttf/.otf in there and
# it is picked up, no per-file entry here and no rebuild. fontconfig scans
# ~/.local/share/fonts recursively, so the whole directory is linked in as one
# subdirectory, which also leaves the parent free for ad-hoc fonts that should
# not live in the repo.
{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  home.file.".local/share/fonts/dotfiles".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/fonts";
}
