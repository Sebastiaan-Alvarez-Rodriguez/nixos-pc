# made with help of https://nixos.wiki/wiki/NFS
{ config, lib, ... }: let
  cfg = config.my.services.nfs;
in {
  options.my.services.nfs = with lib; {
    enable = mkEnableOption "nfs configuration";
    folders = mkOption {
      type = with types; attrsOf submodule ({ name, ...}: {
        ip = mkOption {
          type = str;
          description = "IP to publish directory on";
          default = "192.168.2.16";
        };
        flags = mkOption {
          type = listOf (str);
          description = "flags to set for folder, conform NFS spec. Looks like: <ip>(<FLAGS>)";
          default = ["rw" "nohide" "insecure" "no_subtree_check"];
        }
      });
    };
  };

  config = lib.mkIf cfg.enable {
    services.nfs.server.enable = true;
    services.nfs.server.exports = let
      mkFlags = list: lib.strings.concatStringSep "," list; 
      mkEntry = name: props: "${name} ${props.ip}(${mkFlags props.flags})";
    in 
      lib.strings.concatStringSep "\n" (lib.mapAttrsToList mkEntry cfg.folders)
    # ''
    #   /export         192.168.1.10(rw,fsid=0,no_subtree_check) 192.168.1.15(rw,fsid=0,no_subtree_check)
    #   /export/kotomi  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
    #   /export/mafuyu  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
    #   /export/sen     192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
    #   /export/tomoyo  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
    # '';
  };
}
