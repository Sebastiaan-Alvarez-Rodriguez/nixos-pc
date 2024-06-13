# Google Cloudtop configuration
{ lib, pkgs, ... }:
{
  # Google specific configuration
  home.homeDirectory = "/usr/local/google/home/ambroisie";

  services.gpg-agent.enable = lib.mkForce false;

  my.home = {
    git = {
      package = pkgs.emptyDirectory;
    };
  };
}
