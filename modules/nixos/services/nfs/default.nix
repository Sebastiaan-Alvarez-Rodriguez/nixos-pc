# made with help of https://nixos.wiki/wiki/NFS
# NOTE: NFS is NOT meant to share files over the worldwide web and does not provide sufficient security for it.
# The combination of 'being able to access NFS anywhere' and 'only allow local NFS logins' may be achieved using: a VPN, or, kerberos.
# Both techniques provide local-like access from the worldwide internet, after authentication.
{ config, lib, ... }: let
  cfg = config.my.services.nfs;
in {
  options.my.services.nfs = with lib; {
    enable = mkEnableOption "nfs configuration";
    folders = mkOption {
      type = with types; attrsOf (listOf (submodule ({ name, ... }: {
        options = {
          subnet = mkOption {
            type = str;
            description = "IP subnet / machine names / netgroups to publish directory on.";
            default = "192.168.1.0/24";
          };
          flags = mkOption {
            type = listOf str;
            description = "Flags to set for folder, conform NFS spec (see `man 5 exports`, or https://linux.die.net/man/5/exports).";
            default = ["ro" "sync" "hide" "insecure" "subtree_check"];
          };
        };
      })));
      description = "A list of folders to export via NFS, each with their own subnets and flags.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nfs.server = {
      enable = false; # seb: TODO port 111 may be used as DDoS relay, by sending incorrect login attempts with a fake 'src' address. The 'incorrect login' then forwards to the fake 'src' address, it seems.
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;

      exports = let
        mkFlags = list: lib.strings.concatStringsSep "," list; # produces: "rw,no_subtree_check"
        mkRule = attrs: "${attrs.subnet}(${(mkFlags attrs.flags)})"; # produces: "192.168.1.0/24(<above>)"
        mkEntry = name: listOfAttrs: "${name} ${(lib.concatStringsSep " " (builtins.map mkRule listOfAttrs))}"; # produces: "/data <above> (<above>...)"
      in
        lib.concatStringsSep "\n" (lib.mapAttrsToList mkEntry cfg.folders); # produces multiple lines of above
        # Total looks like:
        # "/export         192.168.1.10(rw,fsid=0,no_subtree_check) 192.168.1.15(rw,fsid=0,no_subtree_check)
        # /export/kotomi  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
        # /export/mafuyu  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
        # /export/sen     192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
        # /export/tomoyo  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)"
    };

    networking.firewall = {
      allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ]; # 2049 is for NFSv4. Others are for NFSv3.
      allowedUDPPorts = [ 111 2049 4000 4001  4002 20048 ];
    };
  };
}
