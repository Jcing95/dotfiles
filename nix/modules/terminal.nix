# Enable zsh as system shell (NixOS)
# All zsh configuration (aliases, history, plugins) is managed by home-manager
{ ... }:

{
  programs.zsh.enable = true;
}
