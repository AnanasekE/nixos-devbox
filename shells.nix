{ pkgs }:
let
  shell = packages: pkgs.mkShell { inherit packages; };
in
{
  default = shell (with pkgs; [ git gnumake ]);

  go = shell (with pkgs; [
    go gopls gotools gofumpt golangci-lint delve templ
  ]);

  node = shell (with pkgs; [
    nodejs_22 pnpm typescript typescript-language-server
  ]);

  python = shell (with pkgs; [
    python3 uv ruff pyright
  ]);

  rust = shell (with pkgs; [
    cargo rustc rustfmt clippy rust-analyzer
  ]);
}
