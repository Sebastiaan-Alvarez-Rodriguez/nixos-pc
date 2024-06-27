# extended lib with custom 'my' functionality
{ self, nixpkgs, inputs, ... }: nixpkgs.lib.extend (final: _: {
  # seb: done using https://www.youtube.com/watch?v=-ohLh-QHc_A
  # seb: guy asking (with some helpful links): https://www.reddit.com/r/NixOS/comments/q8ukbn/is_there_a_simple_way_to_extend_lib/?rdt=33891
  my = import "${self}/lib" { inherit inputs; pkgs = nixpkgs; lib = final; };
})
