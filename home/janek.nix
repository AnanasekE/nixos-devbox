# Home Manager for janek.
# Dotfiles are cloned to ~/dotfiles (a normal git checkout, editable and pushable)
# and linked into $HOME with out-of-store symlinks, so edits apply immediately
# without a rebuild, and lazy.nvim can write lazy-lock.json.
{ config, pkgs, lib, ... }:
let
  home = config.home.homeDirectory;
  dotfiles = "${home}/dotfiles";
  devbox = "${home}/nixos-devbox";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  git = "${pkgs.git}/bin/git";
in
{
  home.username = "janek";
  home.homeDirectory = "/home/janek";
  home.stateVersion = "26.05";

  # ---- Clone repos on first activation --------------------------------------
  home.activation.cloneRepos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.openssh}/bin:$PATH"
    if [ ! -d "${dotfiles}/.git" ]; then
      run ${git} clone --recurse-submodules https://github.com/AnanasekE/dotfiles.git "${dotfiles}" \
        || warnEcho "Cloning dotfiles failed. Rerun: sudo systemctl restart home-manager-janek"
    fi
    if [ ! -d "${home}/.tmux/plugins/tpm" ]; then
      run ${git} clone --depth 1 https://github.com/tmux-plugins/tpm "${home}/.tmux/plugins/tpm" \
        || warnEcho "Cloning tpm failed."
    fi
  '';

  # ---- Dotfiles (headless subset; hypr/waybar/kitty/gtk are desktop-only) ---
  home.file.".zshrc".source = link "zsh/.zshrc";
  home.file.".tmux.conf".source = link "tmux/.tmux.conf";
  xdg.configFile."nvim".source = link "nvim/.config/nvim";
  xdg.configFile."starship".source = link "starship/.config/starship";

  # Global Claude Code memory: tells Claude how this machine works in every project.
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${devbox}/claude/user-CLAUDE.md";

  # ---- Git ------------------------------------------------------------------
  programs.git = {
    enable = true;
    settings = {
      # REPLACE with your identity
      user.name = "AnanasekE";
      user.email = "you@example.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  programs.home-manager.enable = true;
}
