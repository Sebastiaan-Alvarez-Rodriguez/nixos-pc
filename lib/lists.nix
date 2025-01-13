{ lib, ... }: let
  inherit (lib) filter foldl';
in {
  # Count the number of appararitions of each value in a list.
  #
  # countValues ::
  #   [ any ] -> ({ any = int; })
  countValues = let
    addToCount = acc: x: let
      v = toString x;
    in
      acc // { ${v} = (acc.${v} or 0) + 1; };
  in
    foldl' addToCount { };

  # Filter a list using a predicate function after applying a map.
  #
  # mapFilter ::
  #   (value -> bool)
  #   (any -> value)
  #   [ any ]
  mapFilter = pred: f: attrs: filter pred (map f attrs);

  # Transform a nullable value into a list of zero/one element.
  #
  # nullableToList ::
  #   (nullable a) -> [ a ]
  nullableToList = x: if x != null then [ x ] else [ ];

  # Transform a list of names and 1 data definition to a attrset where each name points to the passed data.
  #
  # toAttrsUniform ::
  #   [str]
  #   any
  #   { str = any; }
  toAttrsUniform = names: data: builtins.listToAttrs (lib.map (elem: lib.nameValuePair elem data ) names);
}
