{ pkgs }: let
  quickPackage = {
    # Function to automatically generate a derivation for a single-file script, scene or automation.
    # This function also tests the validity of the script.
    # 1. The package src is located at `/pkgs/hass/script-scope/<name>/`
    # 2. The single-file to package is at `/pkgs/hass/script-scope/<name>/default.yaml`
    # 3. The version file describing the version is at `pkgs/hass/script-scope/<name>/version`
    # seb NOTE: !!!!!!!!!!! only tested with scripts. With scenes, it seems 'include_dir_list' is used instead of 'include_dir_named' in the testing part.
    # This means that (in case the current code is wrong) scenes will throw a whole bunch of nonsensical errors OR it will seem to pass, but be incorrect when verifying with the HA UI.

    # intel:
    # 1. generate yaml, validate with lint: https://kokada.dev/blog/generating-yaml-files-with-nix/
    # 2. read yaml, in pure nix or with commands: https://discourse.nixos.org/t/is-there-a-way-to-read-a-yaml-file-and-get-back-a-set/18385/4
    # considerations:
    # 1. preferably uses home-assistant lint to validate on build time, or otherwise normal yaml lint.
    # 2. yaml in a separate yaml file
    # 3. has a version specified in the script directory, in yaml or in separate file
    name, # name of the package
    domain, # domain of the package. Either 'script', 'scene' or 'automation'.
    ignore-warnings ? false # Determines if this package build halts on encountering warnings (e.g. unused keys) 
  }: let
    domain-options = [ "script" "scene" "automation" ];
  in assert builtins.elem domain domain-options || abort "The domain was not configured to a valid value. Options: [${builtins.toString domain-options}]. Found: ${domain}"; pkgs.stdenvNoCC.mkDerivation rec {
    # assert (builtins.elem domain [ "script" "scene" "automation" ]);
    # uses a separate version file. Just copies the yaml, no checks.
    pname = name;
    version = (pkgs.lib.fileContents ./${name}/version); # use instead of builtins.readFile to remove trailing '\n'
    src = ./${name};


    dontUnpack = true;

    buildPhase = let
      # below 3 lines are a trick to ensure 'colorlog' package is available (needed for checking config)
      ha = pkgs.home-assistant;
      python-with-colorlog = ha.python.withPackages (ps: [ ps.colorlog ]);
      hass-wrap = pkgs.writeShellScript "hass" ''
        export PYTHONPATH=${python-with-colorlog}/${python-with-colorlog.sitePackages}:$PYTHONPATH
        echo "$@"
        exec ${ha}/bin/hass "$@"
      '';
    in if ignore-warnings then ''
      mkdir config
      echo "${domain} split: !include_dir_named ${src}" > config/configuration.yaml
      ${hass-wrap} --script check_config --config ./config
    '' else ''
      mkdir config
      echo "${domain} split: !include_dir_named ${src}" > config/configuration.yaml
      ${hass-wrap} --script check_config --config ./config  2>&1 | tee config/log.txt

      # Fail build if warning is detected
      if grep -i except config/log.txt; then
        echo "Build failed due to above Home Assistant exceptions"
        exit 1
      fi
      if grep -i error config/log.txt; then
        echo "Build failed due to above Home Assistant errors"
        exit 1
      fi
      if grep -i warn config/log.txt; then
        echo "Build failed due to above Home Assistant warnings"
        exit 1
      fi
    '';

    installPhase = ''
      mkdir -p $out
      cp $src/default.yaml $out/default.yaml
    '';
  };
in {
  emergency_notify = quickPackage {name="emergency_notify"; domain="script";};
}
