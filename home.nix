{ config, pkgs, ... }:

{
    home.username = "offlinebot";
    home.homeDirectory = "/home/offlinebot";
    nixpkgs.config.allowUnfree = true;

    home.stateVersion = "26.05"; # Please read the comment before changing.

    home.packages = with pkgs; [
        vim
        neovim
        kitty
        git
        stow
        fuzzel
        awww
        gcc 
        quickshell
        wl-clipboard
        btop
        cowsay
        go rustup
        zoxide
        discord
        gh

        unzip zip
        claude-code
        fastfetch
    ];

    home.sessionVariables = {
        EDITOR = "nvim";
    };

    programs.home-manager.enable = true;
}
