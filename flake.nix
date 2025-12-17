{
  description = "Nix flake for \"too much bleeding-edge\" and unreleased packages (e.g., mesa_git, linux_cachyos, firefox_nightly, sway_git, gamescope_git). And experimental modules (e.g., HDR, duckdns).";

  inputs = {
    # For all users
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      eachSystem =
        accu: system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        accu
        // {
          # Exposes the packages created by the overlay.
          legacyPackages = (accu.legacyPackages or { }) // {
            ${system} = accu.utils.applyOverlay { inherit pkgs; };
          };
          packages = (accu.packages or { }) // {
            ${system} = accu.utils.applyOverlay {
              inherit pkgs;
              onlyDerivations = true;
            };
          };

          # Needed to build without impure
          unrestrictedPackages = (accu.unrestrictedPackages or { }) // {
            ${system} = accu.utils.applyOverlay {
              pkgs = import nixpkgs {
                inherit system;
                config = {
                  allowUnfree = true;
                  allowUnsupportedSystem = true;
                  nvidia.acceptLicense = true;
                };
              };
            };
          };

          # I would prefer if we had something stricter, with attribute alphabetical
          # sorting, and optimized for git's diffing. But this is the closer we have.
          formatter = (accu.formatter or { }) // {
            ${system} = import ./maintenance/formatter.nix pkgs;
          };
        };

      universals = {
        # To fix `nix show` and FlakeHub
        schemas = import ./maintenance/schemas { flakes = inputs; };

        # The stars: our overlay and our modules.
        overlays.default = import ./overlays { flakes = inputs; };
        nixosModules = import ./modules/nixos { flakes = inputs; };

        # Dev stuff.
        utils = import ./shared/utils.nix {
          nyxOverlay = self.overlays.default;
          inherit (nixpkgs) lib;
        };
        inherit (import ./flake.nix) nixConfig;
      };
    in
    builtins.foldl' eachSystem universals [
      "x86_64-linux"
    ];

  # Allows the user to use our cache when using `nix run <thisFlake>`.
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org/"
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };
}
