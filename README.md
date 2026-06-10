# nix-configuration

Meine NixOS Config. Ein Repo, zwei Branches:

- Branch `system` liegt unter `~/.nix` und enthaelt die `configuration.nix` (Flake).
- Branch `home` liegt unter `~/.home` und enthaelt die Home-Manager Config (Flake).

## Struktur

```
~/.nix    (branch: system)        ~/.home   (branch: home)
  flake.nix                         flake.nix
  configuration.nix                 home.nix
  hardware-configuration.nix
```

## Anwenden

System:

```sh
sudo nixos-rebuild switch --flake ~/.nix#nixos
```

Home-Manager:

```sh
home-manager switch --flake ~/.home#offlinebot
```

## System (configuration.nix)

- Bootloader: systemd-boot (UEFI)
- Desktop: GNOME (GDM) und niri
- Audio: PipeWire
- Shell: fish
- Netzwerk: NetworkManager, Tailscale
- Browser: Firefox
- Locale: en_US.UTF-8 mit de_DE Regional, Zeitzone Europe/Berlin

