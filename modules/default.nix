{ config, lib, pkgs, ... }:

{
  imports = [
    ./services/lx-music-sync-server.nix
  ];
}
