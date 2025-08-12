# seb TODO: latest problem is: https://discourse.nixos.org/t/buildnpmpackage-with-path-dependencies/67543
# as if npm-deps.drv cannot fetch the stuff
# this guy got working stuff it seems: https://github.com/NixOS/nixpkgs/blob/5a3cff76fa41a099c2c9cdf1053ed4dc61da971e/pkgs/by-name/vs/vscode-langservers-extracted/package.nix#L11

{ lib, buildNpmPackage, fetchFromGitHub }: let
  rev-nodejs-langs = "584beab4032469f6b76be1d119a0ab25f31f4ab6";
  rev-spatial-navigation = "64871b1422466f5f45d24ebc8bbd315b2ebab6a6";
  rev-stremio-translations = "8212fa77c4febd22ddb611590e9fb574dc845416";
  rev-vtt-js = "84d33d157848407d790d78423dacc41a096294f0";
  nodejs-langs = fetchFromGitHub rec {
    owner = "Stremio";
    repo = "nodejs-langs";
    rev = rev-nodejs-langs;
    hash = "sha256-iQZp1uqRClU3rz/f5eIALYCOS/9xuZDuaBAAHCJlT5E=";
    name = repo; # essential to get a repo named "spatial navigation" and not have unpack conflicts
  };
  spatial-navigation = fetchFromGitHub rec {
    owner = "Stremio";
    repo = "spatial-navigation";
    rev = rev-spatial-navigation;
    hash = "sha256-VFex+2HbaoLYYJ2sbs7v1rFTxVB71UMCHrJPF313jvI=";
    name = repo;
  };
  stremio-translations = fetchFromGitHub rec {
    owner = "Stremio";
    repo = "stremio-translations";
    rev = rev-stremio-translations;
    hash = "sha256-9bfGV2W0VwlVWn2EBEz9oQK6kVuM91UL7xuQNpvbxtM=";
    name = repo;
  };
  vtt-js = fetchFromGitHub rec {
    owner = "jaruba";
    repo = "vtt.js";
    rev = rev-vtt-js;
    hash = "sha256-QYWbJyBhGpXTrDIG715GmjbDlZ9vBNgTQsIaBguFnn8=";
    name = "vtt-js";
  };
in buildNpmPackage rec {
  pname = "stremio-web";
  version = "5.0.0-beta.26";

  # stremio-web depends on below github-hosted dependencies, which npm tries to fetch during build time (and fails, no internet during sandbox pure builds).
  # So we fetch these extra sources below in `srcs` instead of `src`.
  # Then we patch `stremio-web` to actually use the fetched github deps instead of trying to access the internet.

  srcs = [
    (fetchFromGitHub {
      owner = "Stremio";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-UQX54ngv5LYtumD3CMCHfvCVoslwvHP7Q+RLWw/qaGs=";
      name = pname;
    })
    nodejs-langs
    spatial-navigation
    stremio-translations
    vtt-js
  ];

  srcRoot = pname;
  sourceRoot = pname;

  # forceGitDeps = true;
  makeCacheWritable = true;
  npmDepsHash = lib.fakeHash; #"sha256-anj1lY/qnlAkfzKWmvFQqNnyY0vzqEfIEatvkkhhO0I=";
  npmBuildScript = "production";

  # npmFlags = [ "--prefer-offline" ]; # accept whatever is found in cache

  # we change the package.json and package-lock.json to redirect github dependencies (which are not cached correctly) to our local dependencies.
  # Uses: https://docs.npmjs.com/cli/v9/configuring-npm/package-json#local-paths
  # Uses: https://nixos.org/manual/nixpkgs/stable/#fun-substitute
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    substituteInPlace package-lock.json \
      --replace-fail 'github:Stremio/nodejs-langs' 'file:./../nodejs-langs' \
      --replace-fail 'github:Stremio/spatial-navigation#${rev-spatial-navigation}' 'file:./../spatial-navigation' \
      --replace-fail 'github:Stremio/stremio-translations#${rev-stremio-translations}' 'file:./../stremio-translations' \
      --replace-fail 'github:jaruba/vtt.js#${rev-vtt-js}' 'file:./../vtt-js' \
      --subst-var-by 'loc-nodejs-langs' 'file:./../nodejs-langs' \
      --subst-var-by 'loc-spatial-navigation' 'file:./../spatial-navigation' \
      --subst-var-by 'loc-stremio-translations' 'file:./../stremio-translations' \
      --subst-var-by 'loc-vtt-js' 'file:./../vtt-js'
    substituteInPlace package.json \
      --replace-fail 'github:Stremio/nodejs-langs' 'file:./../nodejs-langs' \
      --replace-fail 'github:Stremio/spatial-navigation#${rev-spatial-navigation}' 'file:./../spatial-navigation' \
      --replace-fail 'github:Stremio/stremio-translations#${rev-stremio-translations}' 'file:./../stremio-translations'
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist $out/share/stremio-web
    runHook postInstall
  '';

  meta = with lib; {
    description = "Stremio Web UI (self-hostable)";
    homepage = "https://github.com/Stremio/stremio-web";
    license = licenses.gpl2;
    platforms = platforms.all;
  };
}
