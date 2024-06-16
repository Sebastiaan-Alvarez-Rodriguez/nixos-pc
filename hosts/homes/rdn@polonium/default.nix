{ lib, options, pkgs, ... }: {
  services.gpg-agent.enable = lib.mkForce false;

  my.home = {
    git = {
      package = pkgs.emptyDirectory;
    };

    ssh = {
      mosh = {
        package = pkgs.emptyDirectory;
      };
    };
  };
}
