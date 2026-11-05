{
  description = "Python dev shell (uv)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            python3 uv ruff pyright
          ];
          UV_PYTHON_DOWNLOADS = "never";
          shellHook = ''
            [ -f pyproject.toml ] && uv sync --quiet || true
            [ -d .venv ] && source .venv/bin/activate
          '';
        };
      });
    };
}
