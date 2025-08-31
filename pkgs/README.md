# Custom packages and scoping
About regular packages:
- In nixOS, reference to packages uses `pkgs.<pkg-name>`.
- Depending on the way you set up `nixpkgs` and the importing of it, it is a large dictionary containing many packages.
- In this repo, `nixpkgs` follows the upstream `nixpkgs`. You can search through the available packages using [search.nixos.org](search.nixos.org).

But sometimes, we need to develop our own packages, because `nixpkgs` does not provide them.
Ideally, you create a merge request to `nixpkgs` with your new package like described [here](https://nixos.wiki/wiki/Nixpkgs/Create_and_debug_packages), but those people are quite busy.
If you want the package now, just use custom packages as explained below.

## Usage
### Adding a package
To add a package named `A`:
1. choose how the package must be referenced - Using `pkgs.A`? or using `pkgs.something.A`?
2. If `pkgs.A` is desired, create a new directory in [`pkgs/main-scope`](/pkgs/main-scope) (does not seem to work right now).
   Otherwise, create directories for each scope (each dir-name will be a new scope)
   and **ONLY** for the last scope, add the suffix `-scope` to the dir-name.
3. In the scope-directory you chose, place a `default.nix`.
   It must contain
  ```nix
  { pkgs }: {
    A = <definition-for-A>;
  }
  ```

Examples of step 3 could be found [here](/pkgs/main-scope/default.nix) (using callPackage) or [here](/pkgs/hass/script-scope/default.nix).

### Referencing a package
Just reference like the path states, e.g. if package named `MYPKG` is stored in `/pkgs/hello/world-scope/MYPKG`,
then reference it as `pkgs.hello.world.MYPKG`.

## How this works
I wrote a function that recursively reads directories and constructs a single overlay which extends `pkgs` with the new scopes it read from the directories.
The code for this function is in [/flake/overlays.nix](/flake/overlays.nix).

Before, it looked like this:
```nix
pkgs = _final: prev: {
  "something" = prev.recurseIntoAttrs (import "${self}/pkgs/something" { pkgs = prev; });
};
```

### Default scope
Uses [/flake/packages.nix](/flake/packages.nix).
It directly imports the [/pkgs/main-scope](/pkgs/main-scope) as an extension of `packages`
> **NOTE** Does not seem to work right now


## Package creation tips

### NPM packages
There are few build environments as anti-reproducible as npm packages.
In nixos, we package npm packages using `buildNpmPackage`.
In the [manual](https://nixos.wiki/wiki/Node.js), we can find this route of building among others.
A user explains [here](https://ryantm.github.io/nixpkgs/languages-frameworks/javascript/) some good practices.


`buildNpmPackage` has an automated helper which fetches npm dependencies ([source](https://github.com/NixOS/nixpkgs/blob/0d00f23f023b7215b3f1035adb5247c8ec180dbc/pkgs/build-support/node/build-npm-package/default.nix#L55)).
It uses `fetchNpmDeps` internally ([source](https://github.com/NixOS/nixpkgs/blob/0d00f23f023b7215b3f1035adb5247c8ec180dbc/pkgs/build-support/node/fetch-npm-deps/default.nix)).
A program `prefetch-npm-deps` also uses it.
We list the usual problems and their fixes below.


#### `ENOTCACHED`
Problem:
```bash
npm error code ENOTCACHED
npm error request to https://registry.npmjs.org/<SOME-PACKAGE-HERE> failed: cache mode is 'only-if-cached' but no cached response is available.
```
This means that an instance of `<SOME-PACKAGE-HERE>` in the `package-lock.json` upstream misses `resolved` and `integrity`.
Then `buildNpmPackage` will not pre-fetch them.
That causes the error.

Solution:
1. clone the repo yourself (at the correct branch) and use:
2. The following command will patch the lockfile to get `resolved` and `integrity` everywhere:
```bash
nix run nixpkgs#npm-lockfile-fix -- package-lock.json
```
3. Finally: vendor the patched `package-lock.json`.

#### 'git'/'ssh' no such file or directory
Problem:
```bash
npm error code ENOENT
npm error syscall spawn git
npm error path git
npm error errno -2
npm error enoent An unknown git error occurred
npm error enoent This is related to npm not being able to find a file.
npm error enoent
```

The `package-lock.json` uses `git+ssh://git@github.com/<user>/<repo>.git#<hash` in one or more `resolved` attributes.
This tells `npm` to git clone those repo's at build time.
NixOS uses no-internet sandbox buildgrounds for reproducibility, so `git clone` won't work.

Solution:
1. in `package-lock.json`, make sure every `git+ssh://` has a revision so it looks like: `git+ssh://git@github.com/<user>/<repo>.git#<hash>`
2. in `package-lock.json`, make sure every `github:<user>/<repo>` has a revision so it looks like: `github:<user>/<repo>#<hash>`
3. like 2, but now check `package.json`

Note this may also occur at buildtime (instead of in the patchPhase).
When that happens, the nodejs code itself tries to spawn a subprocess to do something with git.
Usually looks like `ExecSync('/bin/sh git <something>')`. Search the codebase for these commands and replace them by something else.

#### Other errors
Time to get debugging.
Use the package `prefetch-npm-deps` tool to 


#### Vendor edited `package-lock.json`
Above solutions often want you to vendor a patched `package-lock.json` file.
That is done like this:
1. put it in this nixos-config-repo
2. `git add` it
3. write in the nix package file:
```nix
  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
  ''; # use our patched package-lock.json.
```
