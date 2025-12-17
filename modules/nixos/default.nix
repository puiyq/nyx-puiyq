fromFlakes:
let
  modulesPerFile = {
    hdr = import ./hdr.nix;
    mesa-git = import ./mesa-git.nix;
    nyx-home-check = import ./nyx-home-check.nix;
    nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
    nyx-registry = import ../common/nyx-registry.nix fromFlakes;
  };

  default =
    { ... }:
    {
      imports = builtins.attrValues modulesPerFile;
    };
in
modulesPerFile // { inherit default; }
