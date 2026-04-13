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

    oms = {
      url = "github:codesphere-cloud/oms";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, oms, ... }:
  let
    username = "jcing";
    email = "dev@jcing.de";
    linuxSystem = "x86_64-linux";
    darwinSystem = "aarch64-darwin";
  in
  {
    nixosConfigurations = {
      homelab = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = { inherit username email; };
        modules = [
          ./hosts/homelab
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit username email; };
            home-manager.users.${username} = import ./home/homelab.nix;
          }
        ];
      };

      workstation = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = { inherit username email; };
        modules = [
          ./hosts/workstation
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit username email; };
            home-manager.users.${username} = import ./home/workstation.nix;
          }
        ];
      };
    };

    darwinConfigurations."macbook-jcing" = nix-darwin.lib.darwinSystem {
      system = darwinSystem;
      specialArgs = { inherit username email; };
      modules = [
        ./hosts/macbook
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit username email; omsSrc = oms; };
          home-manager.users.${username} = import ./home/macbook.nix;
        }
      ];
    };

  };
}
