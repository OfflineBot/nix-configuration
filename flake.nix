{
    description = "Home Manager configuration";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        dotfiles = {
            url = "github:OfflineBot/nix-configuration/dotfiles";
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.home-manager.follows = "home-manager";
        };
        catppuccin.url = "github:catppuccin/nix";
    };

    outputs = { nixpkgs, home-manager, dotfiles, ... }@inputs:
        let
            system = "x86_64-linux";
            pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
            };
        in {
            homeConfigurations."offlinebot" = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                extraSpecialArgs = { inherit inputs; };
                modules = [
                    ./home.nix
                    dotfiles.homeManagerModules.default
                ];
            };
        };
}
