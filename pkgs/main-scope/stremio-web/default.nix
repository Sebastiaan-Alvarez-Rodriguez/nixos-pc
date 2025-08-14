# seb TODO: latest problem is: https://discourse.nixos.org/t/buildnpmpackage-with-path-dependencies/67543
# as if npm-deps.drv cannot fetch the stuff
# this guy got working stuff it seems: https://github.com/NixOS/nixpkgs/blob/5a3cff76fa41a099c2c9cdf1053ed4dc61da971e/pkgs/by-name/vs/vscode-langservers-extracted/package.nix#L11

{ lib, buildNpmPackage, fetchFromGitHub, fetchNpmDeps }: let
  rev-stremio-web = "sha256-UQX54ngv5LYtumD3CMCHfvCVoslwvHP7Q+RLWw/qaGs=";
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
  # uses: https://github.com/NixOS/nixpkgs/blob/25.05/pkgs/build-support/node/build-npm-package/default.nix
  # uses: https://github.com/NixOS/nixpkgs/blob/25.05/pkgs/build-support/node/fetch-npm-deps/default.nix
  pname = "stremio-web";
  version = "5.0.0-beta.26";

  # things tried:
  # Always started by adding 'resolved' and 'integrity' everywhere
  # 1. just build it
  #   - does not work: stremio-web depends on git+ssh dependencies, which npm tries to fetch during build time (and fails, no internet during sandbox pure builds).
  #   - strange, should work. It does work for: https://raw.githubusercontent.com/jitsi/jitsi-meet/stable/jitsi-meet_9111/package-lock.json
  # 2. change git+ssh to github download tarball url
  #   - does not work (but it should?)
  # 3. use 'srcs' to get files offline + patch buildfiles
  #   - does not work: fetchNpmDeps does not work with local files.
  # 4. like 3, but fetchNpmDeps patch has no local refs, and we patch that in later
  #   - does not work: checks for consistency between lockfiles in fetchNpmDeps and the main package...
  #   - 'Validating consistency between /build/stremio-web/package-lock.json and '/nix/store/...-stremio-web-npm-deps/package-lock.json'
  # 5. like 4, but patch the main package later so consistency passes
  #   - does not work: it seems I need to do the changes in postPatch for both, so no tricks possible.


  # srcRoot = pname;
  # sourceRoot = pname;
  src = fetchFromGitHub {
      owner = "Stremio";
      repo = pname;
      rev = "v${version}";
      hash = rev-stremio-web;
      name = pname;
    };

  forceGitDeps = false;
  forceEmptyCache = false;
  makeCacheWritable = true;
  npmDeps = fetchNpmDeps {
    inherit forceGitDeps forceEmptyCache src postPatch;
    name = "${pname}-npm-deps";
    hash = npmDepsHash;
  };
  npmDepsHash = "sha256-eprjbiQ4TC6jDB8UxHZ9J3sRArLI8hH/6cB7KWlG7Aw=";
  # npmDepsHash = lib.fakeHash;
  npmBuildScript = "build";

  # npmFlags = [ "--prefer-offline" ]; # accept whatever is found in cache

  # package-lock creation: run `npm-lockfile-fix <path/to/package-lock.json>`
  # Below substitute commands:
  # 1. add correct hash to nodejs-langs (otherwise it cannot be cached)
  # 2. fix the mistake by `npm-lockfile-fix` (it changes git+ssh://... to a npmjs.org link, even though we really need the git+ssh:// one and they are not the same)
  # 3. add correct hash to nodejs-langs (otherwise it cannot be cached)
  # 4. remove need for git and/or internet access to get commit hash.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    substituteInPlace package-lock.json \
      --replace-fail 'github:Stremio/nodejs-langs' 'github:Stremio/nodejs-langs#${rev-nodejs-langs}' \
      --replace-fail 'https://registry.npmjs.org/langs/-/langs-2.0.0.tgz' 'git+ssh://git@github.com/Stremio/nodejs-langs.git#${rev-nodejs-langs}'
    substituteInPlace package.json \
      --replace-fail 'github:Stremio/nodejs-langs' 'github:Stremio/nodejs-langs#${rev-nodejs-langs}'
    substituteInPlace webpack.config.js \
      --replace-fail "COMMIT_HASH = execSync('git rev-parse HEAD').toString().trim()" "COMMIT_HASH = '${rev-stremio-web}'"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    mv build/* $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Stremio Web UI (self-hostable)";
    homepage = "https://github.com/Stremio/stremio-web";
    license = licenses.gpl2;
    platforms = platforms.all;
  };
}
