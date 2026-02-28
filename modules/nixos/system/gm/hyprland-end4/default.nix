# end4 configuration - system part
# as found here: https://github.com/soymou/illogical-flake
{ config, inputs, system, lib, pkgs, ... }: let
  cfg = config.my.system.hyprland-end4;
in {
  options.my.system.hyprland-end4 = with lib; {
    enable = mkEnableOption "enable end4 (system preparation) (do not forget home module activation)";
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = config.networking.networkmanager.enable; message = "end4 needs networkmanager to show network status"; }
    ];
    # Enable Hyprland
    programs.hyprland.enable = true;
    programs.hyprland.package = inputs.nixpkgs-unstable.legacyPackages.${system}.hyprland; # NOTE: this repo relies on latest hyprland (e.g. using hypr 0.53 features while nixpkgs stable ships 0.52)

    # Required services
    services.geoclue2.enable = true;  # For QtPositioning
    services.upower.enable = true; # For battery status

    # System fonts (optional but recommended)
    fonts.packages = with pkgs; [
      rubik
      nerd-fonts.ubuntu
      nerd-fonts.jetbrains-mono
    ];
  };
}
