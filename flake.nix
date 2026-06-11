{
    description = "offlinebot's dotfiles, via home-manager + mkOutOfStoreSymlink";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager, ... }:
        let
            system = "x86_64-linux";
            pkgs = nixpkgs.legacyPackages.${system};
        in
            {
            homeManagerModules.default = { config, lib, pkgs, ... }:
                let
                    dotfiles = "${config.home.homeDirectory}/.dotfiles";
                    repoUrl = "https://github.com/OfflineBot/delete_me_dot.git";
                    link = relpath: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${relpath}";

                    configDirs = builtins.attrNames (
                        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.config)
                    );
                in
                    {
                    # Klont ~/.dotfiles automatisch, falls es fehlt (z.B. frisches System),
                    # damit die mkOutOfStoreSymlinks nicht ins Leere zeigen. Läuft vor dem
                    # Verlinken. Vorhandenes Repo wird NICHT angefasst (keine Pulls -> keine
                    # Konflikte mit lokalen Live-Edits).
                    home.activation.cloneDotfiles =
                        lib.hm.dag.entryBefore [ "writeBoundary" ] ''
                            if [ ! -e "${dotfiles}/.git" ]; then
                                echo "dotfiles fehlen -> klone nach ${dotfiles}"
                                ${pkgs.git}/bin/git clone ${repoUrl} "${dotfiles}"
                            fi
                        '';

                    xdg.configFile = lib.genAttrs configDirs (name: {
                        source = link ".config/${name}";
                    });

                    home.file."Pictures/eclipse.jpg".source = link "Pictures/eclipse.jpg";
                };

            homeConfigurations.offlinebot = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = [
                    self.homeManagerModules.default
                    {
                        home.username = "offlinebot";
                        home.homeDirectory = "/home/offlinebot";
                        home.stateVersion = "26.05";
                    }
                ];
            };
        };
}
