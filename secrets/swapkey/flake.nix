{
  description = "swapkey";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };

      buildPythonPackages = pkgs.python312Packages;

      swapkey = buildPythonPackages.buildPythonApplication { # Our build
        pname = "swapkey";
        version = "0.0.1";

        # pyproject = true;
        build-system = [ buildPythonPackages.setuptools ];

        meta.description = "Small project to quickly migrate secrets from 1 key to another key";
        src = ./.;

        # propagatedBuildInputs = with buildPythonPackages; [ numpy pandas scipy matplotlib];

        dontUseSetuptoolsCheck = true; # By default tests are executed, but we don't want to.
      };
    in rec {
      apps.default = flake-utils.lib.mkApp {
        drv = packages.default;
      };
      packages.default = swapkey;
      devShells.default = pkgs.mkShell rec {
        # packages = with buildPythonPackages; [ numpy pandas scipy matplotlib];
      };
    }
  );
}

