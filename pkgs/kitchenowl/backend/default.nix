# modified from https://cyberchaos.dev/kloenk/nix/-/blob/main/pkgs/kitchenowl/backend.nix
{ pkgs, lib, ... }: let
  version = "0.6.10";
  src = pkgs.fetchFromGitHub {
  	owner = "TomBursch";
  	repo = "Kitchenowl";
  	rev = "v${version}";
  	hash = "sha256-Fc6sjmf6V54Fg0TfkGo2khlXm2Rrk3TCGMsEyY42bCg=";
  };

  packageOverrides = final: prev: {
    oic = final.buildPythonPackage rec {
      src = pkgs.fetchFromGitHub {
        owner = "CZ-NIC";
        repo = "pyoidc";
        rev = version;
        hash = "sha256-7qEK1HWLEGCKu+gDAfbyT1a+sM9fVOfjtkqZ33GWv6U=";
      };
      buildInputs = with final; [ responses testfixtures pytest freezegun ];
      propagatedBuildInputs = with final; [ requests pycryptodomex pydantic-settings pyjwkest mako cryptography defusedxml ];
      pname = "oic";
      version = "1.7.0";
    };
    extruct = prev.extruct.overrideAttrs (oldAttrs: {
      version = "0.17.0";
      src = pkgs.fetchFromGitHub {
        owner = "scrapinghub";
        repo = "extruct";
        rev = "refs/tags/v0.17.0";
        hash = "sha256-CfhIqbhrZkJ232grhHxrmj4H1/Bq33ZXe8kovSOWSK0=";
      };
    });
    flask-basicauth = final.buildPythonPackage {
      pname = "flask-basicauth";
      version = "0.2.0";
      src = pkgs.fetchPypi {
        version = "0.2.0";
        pname = "Flask-BasicAuth";
        hash = "sha256-3169SJ3AkUwiRBnaBZ2ZHrcpiKAc3UuVbVKTLOfVAf8=";
      };
      propagatedBuildInputs = with final; [ flask ];
      doCheck = false;
    };
    flask-apscheduler = final.buildPythonPackage {
      pname = "Flask-APScheduler";
      version = "1.13.1";
      src = pkgs.fetchPypi {
        version = "1.13.1";
        pname = "Flask-APScheduler";
        hash = "sha256-uSmEbwJvszm3Y2Cw5Px12ni3XG0IYlcVvQ03lJvWB9o=";
      };
      propagatedBuildInputs = with final; [ flask apscheduler python-dateutil ];
    };
    sqlite-icu = final.buildPythonPackage {
      pname = "sqlite-icu";
      version = "1.0";
      src = pkgs.fetchPypi {
        pname = "sqlite-icu";
        version = "1.0";
        hash = "sha256-lzyvQfMWcv7XyAUyfB1Ydjb42MvH9uVIbslNaRcDbt0=";
      };
      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ icu sqlite ];
    };
    ingredient-parser-nlp = final.buildPythonPackage {
      pname = "ingredient-parser-nlp";
      version = "1.0.0";
      src = pkgs.fetchFromGitHub {
        owner = "strangetom";
        repo = "ingredient-parser";
        rev = "1.0.0";
        hash = "sha256-xylOF8oQsreZ785pcMgMXja8oR4kJrPaibP4bRbrz8c=";
      };
      nativeBuildInputs = [ final.setuptools ];
      propagatedBuildInputs = with final; [ nltk pint python-crfsuite ];
      pyproject = true;
    };
    mlextend = final.buildPythonPackage {
      pname = "mlextend";
      version = "0.23.1";
      src = pkgs.fetchFromGitHub {
        owner = "rasbt";
        repo = "mlxtend";
        rev = "v0.23.1";
        hash = "sha256-FlP6UqX/Ejk9c3Enm0EJ0xqy7iOhDlFqjWWxd4VIczQ=";
      };
      nativeBuildInputs = [ final.setuptools ];
      propagatedBuildInputs = with final; [ scipy numpy pandas scikit-learn matplotlib joblib ];
      pyproject = true;
    };
    dbscan1d = final.buildPythonPackage {
      pname = "dbscan1d";
      version = "0.2.2";
      src = pkgs.fetchPypi {
        version = "0.2.2";
        pname = "dbscan1d";
        hash = "sha256-lgA4T3sJvU9db/A03/sA+exeP2XoqX7pWiueyT7ZahI=";
      };
      pyproject = true;
      nativeBuildInputs = [ final.setuptools-scm ];
      propagatedBuildInputs = with final; [ numpy ];
    };
  };

  python3' = pkgs.python3.override { inherit packageOverrides; };
  python3Packages = python3'.pkgs;
in python3Packages.buildPythonApplication rec {
  pname = "kitchenowl-backend";
  inherit version src;
  patches = [ ./no-basicauth.diff ];
  postPatch = ''
    cd backend
    rm entrypoint.sh Dockerfile
  '';

  installPhase = ''
    mkdir -p $out/opt/kitchenowl
    cp -r . $out/opt/kitchenowl
  '';

  format = "other";

  propagatedBuildInputs = with python3Packages; [
    aiohappyeyeballs
    aiohttp
    aiosignal
    alembic
    amqp
    annotated-types
    anyio
    apispec
    appdirs
    apscheduler
    attrs
    autopep8
    bcrypt
    beautifulsoup4
    bidict
    billiard
    black
    blinker
    blurhash-python
    celery
    certifi
    cffi
    charset-normalizer
    click
    click-didyoumean
    click-plugins
    click-repl
    contourpy
    coverage
    cryptography
    cycler
    dbscan1d
    defusedxml
    extruct
    filelock
    flake8
    flask
    flask-apscheduler
    #flask-basicauth
    flask-bcrypt
    flask-jwt-extended
    flask-migrate
    flask-socketio
    flask-sqlalchemy
    flexcache
    flexparser
    fonttools
    frozenlist
    fsspec
    future
    gevent
    greenlet
    h11
    html-text
    html5lib
    httpcore
    httpx
    huggingface-hub
    importlib-metadata
    idna
    ingredient-parser-nlp
    iniconfig
    isodate
    itsdangerous
    jinja2
    joblib
    # jitter
    jsonschema
    jsonschema-spec
    jstyleson
    kiwisolver
    kombu
    lark
    litellm
    lxml
    lxml-html-clean
    mako
    markupsafe
    marshmallow
    matplotlib
    mccabe
    mf2py
    mlextend
    multidict
    mypy-extensions
    nltk
    numpy
    oic
    openai
    packaging
    pandas
    pathspec
    pillow
    pint
    platformdirs
    pluggy
    prometheus-client
    prometheus-flask-exporter
    prompt-toolkit
    propcache
    psycopg2
    py
    pycodestyle
    pycparser
    pycryptodomex
    pydantic
    pydantic-settings
    pyflakes
    pyjwkest
    pyjwt
    pyparsing
    pyrdfa3
    pytest
    python-crfsuite
    python-dateutil
    python-dotenv
    python-editor
    python-engineio
    python-socketio
    pytz
    pytz-deprecation-shim
    pyyaml
    rdflib
    #rdflib-jsonld
    recipe-scrapers
    referencing
    regex
    requests
    rpds-py
    scikit-learn
    scipy
    setuptools-scm
    simple-websocket
    six
    soupsieve
    sqlalchemy
    sqlite-icu
    threadpoolctl
    tiktoken
    tokenizers
    toml
    tomli
    tqdm
    typed-ast
    types-beautifulsoup4
    types-html5lib
    types-requests
    types-urllib3
    typing-extensions
    tzdata
    tzlocal
    urllib3
    # uwsgi
    # uwsgi-tools
    vine
    w3lib
    wcwidth
    webencodings
    werkzeug
    wsproto
    yarl
    zipp
    zope-event
    zope-interface
  ];

  passthru = {
    pythonPath = python3Packages.makePythonPath propagatedBuildInputs;
    nltkData = with pkgs.nltk-data; [ averaged_perceptron_tagger ];
    inherit python3Packages;
  };
}
