# Workstation-specific desktop configuration
{ pkgs, ... }:

{
  imports = [ ./hyprland.nix ];

  # Display manager — regreet (GTK4 under cage), themed via regreet/regreet.css
  services.displayManager.regreet = {
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
