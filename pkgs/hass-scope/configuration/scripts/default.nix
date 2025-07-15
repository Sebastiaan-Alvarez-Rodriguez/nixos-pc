{ pkgs }: let
  # intel:
  # 1. generate yaml, validate with lint: https://kokada.dev/blog/generating-yaml-files-with-nix/
  # 2. read yaml, in pure nix or with commands: https://discourse.nixos.org/t/is-there-a-way-to-read-a-yaml-file-and-get-back-a-set/18385/4
  # considerations:
  # 1. preferably uses home-assistant lint to validate on build time, or otherwise normal yaml lint.
  # 2. yaml in a separate yaml file
  # 3. has a version specified in the script directory, in yaml or in separate file

  # quickPackage = name: stdenvNoCC.mkDerivation rec {
  #   # uses a separate version file. Just copies the yaml, no checks.
  #   pname = name;
  #   version = (builtins.readFile ./name/version);

  #   src = ./${name}/default.yaml;

  #   dontUnpack = true;

  #   buildInputs = with pkgs; [ action-validator ];
  #   buildPhase = ''
  #     action-validator -v $src
  #   '';

  #   installPhase = ''
  #     mkdir -p $out
  #     cp $src $out/
  #   '';
  # }
  quickPackage = name: domain: stdenvNoCC.mkDerivation rec {
    # uses a separate version file. Just copies the yaml, no checks.
    pname = name;
    version = (builtins.readFile ./name/version);

    src = ./${name}/default.yaml;

    dontUnpack = true;

    buildInputs = with pkgs; [
      home-assistant
      (python3.withPackages (ps: with ps; [ colorlog ]))
    ];
    buildPhase = ''
      mkdir config
      echo "${domain}: !include $src" > config/configuration.yaml 
      hass --skip-pip --config ./config --script check_config
    '';

    installPhase = ''
      mkdir -p $out
      cp $src $out/
    '';
  };
in {
  emergency_notify = quickPackage emergency_notify;
}
