# Conventions:
# - Sort packages in alphabetic order.
# - If the recipe uses `override` or `overrideAttrs`, then use callOverride,
#   otherwise use `final`.
# - Composed names are separated with minus: `lan-mouse`
# - Versions/patches are suffixed with an underline: `mesa_git`, `libei_0_5`, `linux_hdr`

# NOTE:
# - `*_next` packages will be removed once merged into nixpkgs-unstable.

{
  flakes,
  nixpkgs ? flakes.nixpkgs,
  self ? flakes.self,
  selfOverlay ? self.overlays.default,
  nixpkgsExtraConfig ? { },
}:
final: prev:

let
  # Required to load version files.
  inherit (final.lib.trivial) importJSON;

  # Our utilities/helpers.
  nyxUtils = import ../shared/utils.nix {
    inherit (final) lib;
    nyxOverlay = selfOverlay;
  };
  inherit (nyxUtils) drvDropUpdateScript;

  # Helps when calling .nix that will override packages.
  callOverride =
    path: attrs:
    import path (
      {
        inherit
          final
          flakes
          nyxUtils
          prev
          gitOverride
          ;
      }
      // attrs
    );

  # Helps when calling .nix that will override i686-packages.
  callOverride32 =
    path: attrs:
    import path (
      {
        inherit flakes nyxUtils gitOverride;
        final = final.pkgsi686Linux;
        final64 = final;
        prev = prev.pkgsi686Linux;
      }
      // attrs
    );

  # Magic helper for _git packages.
  gitOverride = import ../shared/git-override.nix {
    inherit (final)
      lib
      callPackage
      fetchFromGitHub
      fetchFromGitLab
      fetchFromGitea
      ;
    inherit (final.rustPlatform) fetchCargoVendor;
    nyx = self;
    fetchRevFromGitHub = final.callPackage ../shared/github-rev-fetcher.nix { };
    fetchRevFromGitLab = final.callPackage ../shared/gitlab-rev-fetcher.nix { };
    fetchRevFromGitea = final.callPackage ../shared/gitea-rev-fetcher.nix { };
  };

  # Too much variations
  cachyosPackages = callOverride ../pkgs/linux-cachyos { };

  # Microarch stuff
  makeMicroarchPkgs = import ../shared/make-microarch.nix {
    inherit
      nixpkgs
      final
      selfOverlay
      nixpkgsExtraConfig
      ;
  };

  # Required for 32-bit packages
  has32 = final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86;

in
{
  inherit nyxUtils;

  nyx-generic-git-update = final.callPackage ../pkgs/nyx-generic-git-update { };

  linux_cachyos-lto-znver4 = drvDropUpdateScript cachyosPackages.cachyos-lto-znver4.kernel;

  linuxPackages_cachyos-lto-znver4 = cachyosPackages.cachyos-lto-znver4;

  pkgsx86_64_v2 = final.pkgsAMD64Microarchs.x86-64-v2;
  pkgsx86_64_v3 = final.pkgsAMD64Microarchs.x86-64-v3;
  pkgsx86_64_v4 = final.pkgsAMD64Microarchs.x86-64-v4;

  pkgsAMD64Microarchs = builtins.mapAttrs (arch: _inferiors: makeMicroarchPkgs "x86_64" arch) (
    removeAttrs final.lib.systems.architectures.inferiors [
      "default"
      "armv5te"
      "armv6"
      "armv7-a"
      "armv8-a"
      "mips32"
      "loongson2f"
    ]
  );

  proton-cachyos_x86_64_v3 = final.callPackage ../pkgs/proton-bin {
    toolTitle = "Proton-CachyOS x86-64-v3";
    tarballPrefix = "proton-";
    tarballSuffix = "-x86_64_v3.tar.xz";
    toolPattern = "proton-cachyos-.*";
    releasePrefix = "cachyos-";
    releaseSuffix = "-slr";
    versionFilename = "cachyos-v3-version.json";
    owner = "CachyOS";
    repo = "proton-cachyos";
  };
}
