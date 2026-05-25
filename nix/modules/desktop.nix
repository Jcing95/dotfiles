# Workstation-specific desktop configuration
{ pkgs, ... }:

{
  imports = [ ./hyprland.nix ];

  # Additional workstation packages
  environment.systemPackages = with pkgs; [
    hyprshutdown
    wlogout
  ];

  # Display manager — regreet (GTK4 under cage), themed via regreet/regreet.css
  programs.regreet = {
    enable = true;
    theme.name = "Adwaita-dark";
    iconTheme.name = "Adwaita";
    font = {
      name = "FiraCode Nerd Font";
      size = 14;
    };
    extraCss = ../../regreet/regreet.css;
    cageArgs = [ "-s" "-m" "last" ];
  };
}
