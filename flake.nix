{
  description = "NixOS dev box (Proxmox VM) with AnanasekE/dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # claude-code only, see the overlay below
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # nixos-26.05 pins claude-code 2.1.223 while upstream is at 2.1.318,
      # and the CLI version decides which models it offers. Its own
      # instance, so it needs its own allowUnfree.
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.devbox = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/devbox/configuration.nix
          { nixpkgs.overlays = [ (final: prev: { inherit (unstable) claude-code; }) ]; }
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
