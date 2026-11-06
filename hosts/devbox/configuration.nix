{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = "janek";
  flakeDir = "/home/${user}/nixos-devbox";
in
{
  imports = [ ./hardware.nix ];

  networking.hostName = "devbox";
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";

  # ---- Nix -----------------------------------------------------------------
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      user
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true; # claude-code is unfree

  # ---- Proxmox guest + SSH -------------------------------------------------
  services.qemuGuest.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  programs.mosh.enable = true; # opens UDP 60000-61000
  environment.enableAllTerminfo = true; # kitty, alacritty, etc. over SSH

  # ---- User ----------------------------------------------------------------
  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      # REPLACE: paste your public key(s), e.g. from `cat ~/.ssh/id_ed25519.pub`
      # or https://github.com/AnanasekE.keys
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL4FT7jj9QquUO+XMo2/lvPbeG8rlg919nGuzOHEYi2k janek@PC"
    ];
  };
  # Key-only login, so sudo has no password to ask for.
  security.sudo.wheelNeedsPassword = false;

  # ---- Shell ---------------------------------------------------------------
  programs.zsh = {
    enable = true;
    promptInit = ""; # starship from ~/.zshrc handles the prompt
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ${flakeDir}#devbox";
      rebuild-test = "sudo nixos-rebuild test --flake ${flakeDir}#devbox";
      rebuild-update = "nix flake update --flake ${flakeDir} && sudo nixos-rebuild switch --flake ${flakeDir}#devbox";
    };
  };
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    # Dotfiles keep starship.toml in ~/.config/starship/, not the default path.
    STARSHIP_CONFIG = "$HOME/.config/starship/starship.toml";
  };

  # Per-project toolchains: `use flake` in .envrc
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Lets Mason (nvim) and other prebuilt binaries run on NixOS.
  programs.nix-ld.enable = true;

  virtualisation.docker.enable = true;

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # ---- Packages ------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # Claude Code (updates come from `nix flake update`)
    claude-code

    # Core CLI
    git
    gh
    lazygit
    curl
    wget
    jq
    yq-go
    tree
    htop
    btop
    ripgrep
    fd
    fzf
    unzip
    zip
    file
    which
    tmux
    starship
    neovim
    glib # gio, for neo-tree's trash support

    # Needed by kickstart.nvim plugins, Mason and treesitter
    gcc
    gnumake
    tree-sitter
    nodejs_22
    go
    python3
    cargo

    # Nix tooling
    nixd
    nixfmt
    nix-tree
    nvd
  ];

  # `nh os switch` = rebuild with a readable diff of what changed.
  programs.nh = {
    enable = true;
    flake = flakeDir;
  };

  # Clone dotfiles on first boot: wait for network before Home Manager runs.
  systemd.services."home-manager-${user}" = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  system.stateVersion = "26.05";
}
