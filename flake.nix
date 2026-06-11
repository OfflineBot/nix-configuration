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
    };

    outputs = { nixpkgs, home-manager, dotfiles, ... }:
        let
            system = "x86_64-linux";
            pkgs = nixpkgs.legacyPackages.${system};
        in {
            homeConfigurations."offlinebot" = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = [
                    ./home.nix
                    dotfiles.homeManagerModules.default
                ];
            };
        };
}
