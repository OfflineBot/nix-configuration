{ config, pkgs, lib, inputs, ... }:

{
    imports = [ inputs.catppuccin.homeModules.catppuccin ];

    home.username = "offlinebot";
    home.homeDirectory = "/home/offlinebot";

    home.stateVersion = "26.05"; # Please read the comment before changing.

    catppuccin = {
        autoEnable = true;
        flavor = "mocha";
        accent = "blue";
        gtk.icon.enable = true;
    };

    xdg.configFile."gtk-3.0".enable = lib.mkForce false;
    xdg.configFile."gtk-4.0".enable = lib.mkForce false;

    gtk = {
        enable = true;
        theme = {
            name = "catppuccin-mocha-blue-standard";
            package = pkgs.catppuccin-gtk.override {
                accents = [ "blue" ];
                variant = "mocha";
            };
        };
    };

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
        sshfs
        btop
        cowsay
        go rustup
        zoxide
        discord
        gh
        pavucontrol
        brightnessctl
        hyprlock
        xournalpp
        zathura

        unzip zip
        claude-code
        fastfetch
    ];

    home.sessionVariables = {
        EDITOR = "nvim";
    };

    programs.home-manager.enable = true;
}
