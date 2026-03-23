# Workstation-specific desktop configuration
{ pkgs, ... }:

{
  imports = [ ./hyprland.nix ];

  # Additional workstation packages
  environment.systemPackages = with pkgs; [
    hyprshutdown
    wlogout
  ];

  # Display manager with themed tuigreet
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland -g 'Welcome in Jcingspace. Trying to enter the system...' -w 100 --theme 'button=red;text=green;time=red;action=red;container=black;input=red;border=green;prompt=green'";
      user = "greeter";
    };
  };
}
