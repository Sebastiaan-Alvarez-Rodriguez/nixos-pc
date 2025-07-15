# Custom packages and scoping
About regular packages:
- In nixOS, reference to packages uses `pkgs.<pkg-name>`.
- Depending on the way you set up `nixpkgs` and the importing of it, it is a large dictionary containing many packages.
- In this repo, `nixpkgs` follows the upstream `nixpkgs`. You can search through the available packages using [search.nixos.org](search.nixos.org).

But sometimes, we need to develop our own packages, because `nixpkgs` does not provide them.
Ideally, you create a merge request to `nixpkgs` with your new package like described [here](https://nixos.wiki/wiki/Nixpkgs/Create_and_debug_packages), but those people are quite busy.
If you want the package now, just use custom packages as explained below.


## Adding a package
To add a package named `A`:
1. choose how the package must be referenced - Using `pkgs.A`? or using `pkgs.something.A`?
2. If `pkgs.A` is desired, create a new directory in [`pkgs/main-scope`](/pkgs/main-scope).
   Otherwise, create directories for each scope (each dir-name will be a new scope) and for the last scope, add the suffix `-scope` to the dir-name.
3. In the scope-directory you chose, place a `default.nix`.
   It must contain
  ```nix
  { pkgs }: {
    A = <definition-for-A>;
  }
  ```

Examples of step 3 could be found [here](/pkgs/main-scope/default.nix) (using callPackage) or [here](/pkgs/hass/script-scope/default.nix).

## How this works
I wrote a function that recursively reads directories and constructs a single overlay which extends `pkgs` with the new scopes it read from the directories.
The code for this function is in [/flake/overlays.nix](/flake/overlays.nix)
