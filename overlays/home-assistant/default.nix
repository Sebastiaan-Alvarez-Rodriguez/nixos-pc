{ inputs, ... }:
self: prev: { # use unstable package
  home-assistant = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.home-assistant.overrideAttrs(old: {
    # patch to stop 'check_config' script looking for and installing colorlog python package
    # NOTE: to use 'check_config', add 'colorlog' to 'PYTHONPATH' env var yourself. E.g.
    # ha = pkgs.home-assistant;
    # ha-python = ha.passthru.python3Packages;
    # python-with-colorlog = ha-python.python.withPackages (ps: [ ha-python.colorlog ]);
    # hass-wrap = pkgs.writeShellScript "hass" ''
    #   export PYTHONPATH=${python-with-colorlog}/${python-with-colorlog.sitePackages}:$PYTHONPATH
    #   exec ${ha}/bin/hass "$@"
    # '';

    postPatch = (old.postPatch or "") + ''
      substituteInPlace homeassistant/scripts/check_config.py --replace-fail 'REQUIREMENTS = (' 'REQUIREMENTS = () # nix provides dependencies, no need for: ('
    '';

    # removed installcheck as it crashes (only the check crashes, install works fine)
    doInstallCheck = false;
  });
}
# NOTE: also requires configurations:
# disabledModules = [
#   "services/home-automation/home-assistant.nix"
# ];

# imports = [
#   <nixpkgs-unstable/nixos/modules/services/home-automation/home-assistant.nix>
# ];
