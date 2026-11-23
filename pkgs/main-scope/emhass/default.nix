{ pkgs, lib, ... }: let
  buildPythonPackages = pkgs.python314Packages;

  skforecast = buildPythonPackages.buildPythonPackage rec {
    pname = "skforecast";
    version = "0.22.0";

    src = buildPythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-wspSiu5lwEiYH6abLx37vxLZ5xsgCl5s9JptWa1GxQQ=";
    };

    pyproject = true;
    build-system = with buildPythonPackages; [ setuptools toml build ];

    propagatedBuildInputs = with buildPythonPackages; [
      # https://github.com/skforecast/skforecast/blob/0.22.x/pyproject.toml
      numpy
      scipy
      pandas
      tqdm
      scikit-learn
      optuna
      joblib
      numba
      rich
    ];
  };

  pvlib = buildPythonPackages.buildPythonPackage rec {
    pname = "pvlib";
    version = "0.16.1";

    src = buildPythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-WMQ1+TvlFrzt9T3DpJsgeengCvNz9cBSy3z40rlzzmI=";
    };

    pyproject = true;
    build-system = with buildPythonPackages; [ setuptools setuptools-scm ];

    propagatedBuildInputs = with buildPythonPackages; [
      # https://github.com/pvlib/pvlib-python/blob/main/pyproject.toml
      numpy
      scipy
      pandas
      pytz
      requests
      h5py
      tzdata
    ];
  };
in buildPythonPackages.buildPythonApplication rec {
  pname = "emhass";
  version = "0.18.7";

  src = buildPythonPackages.fetchPypi {
    inherit pname version;
    hash = "sha256-Cq5NByUnqGn3ivTCtwSGQUj9XcSDO4SJwcU3g5b9yf4=";
  };

  pyproject = true;
  build-system = [ buildPythonPackages.hatchling ];

  nativeBuildInputs = [ buildPythonPackages.pythonRelaxDepsHook ];
  # nativeBuildInputs = with pkgs.python3Packages; [ pythonRelaxDepsHook ];
  pythonRelaxDeps = [ "numpy" "cvxpy" "uvicorn" ];
  pythonRemoveDeps = [ "asyncio" ]; # this is part of the STL
  propagatedBuildInputs = [
    # buildPythonPackages.setuptools
    # buildPythonPackages.six
    buildPythonPackages.numpy
    buildPythonPackages.scipy
    buildPythonPackages.pandas
    buildPythonPackages.protobuf
    buildPythonPackages.pytz
    buildPythonPackages.h5py
    buildPythonPackages.highspy
    buildPythonPackages.cvxpy
    buildPythonPackages.pyyaml
    buildPythonPackages.tables
    buildPythonPackages.waitress
    buildPythonPackages.plotly
    buildPythonPackages.gunicorn
    buildPythonPackages.quart
    buildPythonPackages.aiofiles
    buildPythonPackages.jinja2
    buildPythonPackages.aiohttp
    buildPythonPackages.orjson
    buildPythonPackages.websockets
    buildPythonPackages.uvicorn
    buildPythonPackages.influxdb
    # own
    pvlib
    skforecast
  ];
  doCheck=false;
  dontUseSetuptoolsCheck = true;


  meta.description = "EMHASS build wrapper in nixOS.";
}
