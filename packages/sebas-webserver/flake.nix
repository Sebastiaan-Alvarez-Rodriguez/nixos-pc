{
  description = "Sebas Webserver";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          permittedInsecurePackages = [
            "qtwebkit-5.212.0-alpha4" # dependency of wkhtmltopdf
            "openssl-1.1.1w" # dependency of wkhtmltopdf
          ];
        };
      };

      buildPythonPackages = pkgs.python3Packages;

      mollie-api-python = pkgs.callPackage nix/dep/mollie-api-python.nix {
        inherit buildPythonPackages;
      };

      django-dynamic-breadcrumbs = pkgs.callPackage nix/dep/django-dynamic-breadcrumbs.nix {
        inherit buildPythonPackages;
      };

      django-nine = pkgs.callPackage nix/dep/django-nine.nix {
        inherit buildPythonPackages;
      };

      django-nonefield = pkgs.callPackage nix/dep/django-nonefield.nix {
        inherit buildPythonPackages django-nine;
      };

      vishap = pkgs.callPackage nix/dep/vishap.nix {
        inherit buildPythonPackages django-nine;
      };

      django-autoslug = pkgs.callPackage nix/dep/django-autoslug.nix {
        inherit buildPythonPackages;
      };

      django-js-asset = pkgs.callPackage nix/dep/django-js-asset.nix {
        inherit buildPythonPackages django-nine;
      };

      django-ckeditor = pkgs.callPackage nix/dep/django-ckeditor.nix {
        inherit buildPythonPackages django-js-asset;
      };

      django-phonenumber-field = pkgs.callPackage nix/dep/django-phonenumber-field.nix {
        inherit buildPythonPackages;
      };

      django-post-office = pkgs.callPackage nix/dep/django-post-office.nix {
        inherit buildPythonPackages;
      };

      django-fobi = pkgs.callPackage nix/dep/django-fobi.nix {
        inherit buildPythonPackages django-autoslug django-ckeditor django-nine django-nonefield django-phonenumber-field vishap;
      };

      django-dbbackup = pkgs.callPackage nix/dep/django-dbbackup.nix {
        inherit buildPythonPackages;
      };

      # Our build
      Sebas-webserver = buildPythonPackages.buildPythonApplication {
        pname = "sebas_webserver";
        version = "1.0.0";

        meta = {
          homepage = "https://github.com/Sebastiaan-Alvarez-Rodriguez/sebas-webserver";
          description = "Webserver.";
        };
        src = ./.;

        propagatedBuildInputs = [
          #deps
          buildPythonPackages.django
          buildPythonPackages.django-environ #==0.8.1
          buildPythonPackages.django-filter
          buildPythonPackages.asgiref
          buildPythonPackages.autopep8
          buildPythonPackages.caldav #==1.2.1
          buildPythonPackages.dj-database-url #==0.5.0
          buildPythonPackages.gunicorn #==20.1.0
          buildPythonPackages.pycodestyle #==2.8.0
          buildPythonPackages.pytz #==2021.3
          buildPythonPackages.sqlparse #==0.4.2
          buildPythonPackages.toml #==0.10.2
          buildPythonPackages.whitenoise #==5.3.0
          buildPythonPackages.psycopg2
          buildPythonPackages.pillow #=9.0.1
          buildPythonPackages.phonenumbers
          buildPythonPackages.pdfkit
          ## deps / build
          buildPythonPackages.setuptools
          buildPythonPackages.six
          ## deps / self-made
          mollie-api-python
          django-dynamic-breadcrumbs 
          django-fobi
          django-dbbackup
          django-post-office
        ];

        # By default tests are executed, but they need to be invoked differently for this package
        dontUseSetuptoolsCheck = true;
      };
    in rec {
      apps.default = flake-utils.lib.mkApp {
        drv = packages.default;
      };
      packages.default = Sebas-webserver;
      devShells.default = pkgs.mkShell rec {
        PGUSER="postgres";
        PGDATABASE="postgres";
        # WKHTMLTOPDF_BIN="${pkgs.wkhtmltopdf-bin}/bin/wkhtmltopdf";
        packages = [
          Sebas-webserver
          # dev
          pkgs.wkhtmltopdf-bin # for invoice generation
          pkgs.postgresql # for django-dbbackup commands.
        ];
      };

      postgres = {
        autoStart = true;
        privateNetwork = true; # no open ports on host to outside world
        extraFlags = [ "-U" ]; # non-privileged container:
        # no ports below 1024, no bindmounts, no root-login
        config = nix/container/postgresql.nix;
      };
    }
  );
}
