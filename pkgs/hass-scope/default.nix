{ pkgs, ... }: {
  # imports = [
  #   ./configuration
  # ];

  visonic = pkgs.callPackage ./visonic {};
}
