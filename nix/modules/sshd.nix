# OpenSSH deamon configuration
{ config, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    
    settings.PasswordAuthentication = false;
    settings.PubkeyAuthentication = true;
    settings.PermitRootLogin = "no";
    
    ports = [ 22420 ];
  };
  users.users.jcing.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRkbqPt+f6ZyGFnz1wCbR21mXhX75Lb6yCxy6OmmMUU dev@jcing.de"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsu6Ktzn5AsGAdnNyHiZOZZIAnMA2zoCCcAlYpwGdk8 dev@jcing.de"
  ];

  networking.firewall = {
    enable=true;
    allowedTCPPorts = [22420];
    allowedUDPPorts = [22420];
  };
}
