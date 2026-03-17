{
  description = "Jcing's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations = {
      homelab = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/homelab
        ];
      };

      workstation = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/workstation
        ];
      };
    };

    homeConfigurations."jcing@workstation" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./home-workstation.nix
        {
          home.username = "jcing";
          home.homeDirectory = "/home/jcing";
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };

    homeConfigurations."jcing@homelab" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./home-homelab.nix
        {
          home.username = "jcing";
          home.homeDirectory = "/home/jcing";
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
  };
}
