{
  description = "Jcing's NixOS & nix-darwin Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }:
  let
    linuxSystem = "x86_64-linux";
    darwinSystem = "aarch64-darwin";
    linuxPkgs = nixpkgs.legacyPackages.${linuxSystem};
    darwinPkgs = nixpkgs.legacyPackages.${darwinSystem};
  in
  {
    nixosConfigurations = {
      homelab = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        modules = [
          ./hosts/homelab
        ];
      };

      workstation = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        modules = [
          ./hosts/workstation
        ];
      };
    };

    darwinConfigurations."macbook-jcing" = nix-darwin.lib.darwinSystem {
      system = darwinSystem;
      modules = [
        ./hosts/macbook
      ];
    };

    homeConfigurations."jcing@workstation" = home-manager.lib.homeManagerConfiguration {
      pkgs = linuxPkgs;
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
      pkgs = linuxPkgs;
      modules = [
        ./home-homelab.nix
        {
          home.username = "jcing";
          home.homeDirectory = "/home/jcing";
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };

    homeConfigurations."jcing@macbook-jcing" = home-manager.lib.homeManagerConfiguration {
      pkgs = darwinPkgs;
      modules = [
        ./home-macbook.nix
        {
          home.username = "jcing";
          home.homeDirectory = "/Users/jcing";
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
  };
}
