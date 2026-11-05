{
  description = "NixOS dev box (Proxmox VM) with AnanasekE/dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations.devbox = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/devbox/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.users.janek = import ./home/janek.nix;
          }
        ];
      };

      # Shared dev shells for projects that should not carry their own flake:
      #   echo 'use flake ~/nixos-devbox#go' > .envrc && direnv allow
      devShells.${system} = import ./shells.nix { inherit pkgs; };

      # Per-project flakes:
      #   nix flake init -t ~/nixos-devbox#go
      templates = {
        default = { path = ./templates/default; description = "Generic dev shell"; };
        go      = { path = ./templates/go;      description = "Go dev shell"; };
        node    = { path = ./templates/node;    description = "Node.js / TypeScript dev shell"; };
        python  = { path = ./templates/python;  description = "Python dev shell (uv)"; };
        rust    = { path = ./templates/rust;    description = "Rust dev shell"; };
      };
    };
}
