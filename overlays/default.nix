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

  ananicy-rules-cachyos_git = callOverride ../pkgs/ananicy-cpp-rules { };

  jujutsu_git = callOverride ../pkgs/jujutsu-git { };

  libdrm_git = callOverride ../pkgs/libdrm-git { };
  libdrm32_git =
    if has32 then callOverride32 ../pkgs/libdrm-git { } else throw "No libdrm32_git for non-x86";

  linux_cachyos = drvDropUpdateScript cachyosPackages.cachyos-gcc.kernel;
  linux_cachyos-lto = drvDropUpdateScript cachyosPackages.cachyos-lto.kernel;
  linux_cachyos-lto-znver4 = drvDropUpdateScript cachyosPackages.cachyos-lto-znver4.kernel;
  linux_cachyos-gcc = drvDropUpdateScript cachyosPackages.cachyos-gcc.kernel;
  linux_cachyos-server = drvDropUpdateScript cachyosPackages.cachyos-server.kernel;
  linux_cachyos-hardened = drvDropUpdateScript cachyosPackages.cachyos-hardened.kernel;
  linux_cachyos-rc = cachyosPackages.cachyos-rc.kernel;
  linux_cachyos-lts = cachyosPackages.cachyos-lts.kernel;

  linuxPackages_cachyos = cachyosPackages.cachyos-gcc;
  linuxPackages_cachyos-lto = cachyosPackages.cachyos-lto;
  linuxPackages_cachyos-lto-znver4 = cachyosPackages.cachyos-lto-znver4;
  linuxPackages_cachyos-gcc = cachyosPackages.cachyos-gcc;
  linuxPackages_cachyos-server = cachyosPackages.cachyos-server;
  linuxPackages_cachyos-hardened = cachyosPackages.cachyos-hardened;
  linuxPackages_cachyos-rc = cachyosPackages.cachyos-rc;
  linuxPackages_cachyos-lts = cachyosPackages.cachyos-lts;

  mesa_git = callOverride ../pkgs/mesa-git { };
  mesa32_git =
    if has32 then callOverride32 ../pkgs/mesa-git { } else throw "No mesa32_git for non-x86";

  pkgsx86_64_v2 = final.pkgsAMD64Microarchs.x86-64-v2;
  pkgsx86_64_v3 = final.pkgsAMD64Microarchs.x86-64-v3;
  pkgsx86_64_v4 = final.pkgsAMD64Microarchs.x86-64-v4;

  pkgsAMD64Microarchs = builtins.mapAttrs (arch: _inferiors: makeMicroarchPkgs "x86_64" arch) (
    builtins.removeAttrs final.lib.systems.architectures.inferiors [
      "default"
      "armv5te"
      "armv6"
      "armv7-a"
      "armv8-a"
      "mips32"
      "loongson2f"
    ]
  );

  proton-cachyos = final.callPackage ../pkgs/proton-bin {
    toolTitle = "Proton-CachyOS";
    tarballPrefix = "proton-";
    tarballSuffix = "-x86_64.tar.xz";
    toolPattern = "proton-cachyos-.*";
    releasePrefix = "cachyos-";
    releaseSuffix = "-slr";
    versionFilename = "cachyos-version.json";
    owner = "CachyOS";
    repo = "proton-cachyos";
  };

  proton-cachyos_x86_64_v2 = final.proton-cachyos.override {
    toolTitle = "Proton-CachyOS x86-64-v2";
    tarballSuffix = "-x86_64_v2.tar.xz";
    versionFilename = "cachyos-v2-version.json";
  };

  proton-cachyos_x86_64_v3 = final.proton-cachyos.override {
    toolTitle = "Proton-CachyOS x86-64-v3";
    tarballSuffix = "-x86_64_v3.tar.xz";
    versionFilename = "cachyos-v3-version.json";
  };

  proton-cachyos_x86_64_v4 = final.proton-cachyos.override {
    toolTitle = "Proton-CachyOS x86-64-v4";
    tarballSuffix = "-x86_64_v4.tar.xz";
    versionFilename = "cachyos-v4-version.json";
  };

  proton-ge-custom = final.callPackage ../pkgs/proton-bin {
    toolTitle = "Proton-GE";
    tarballSuffix = ".tar.gz";
    toolPattern = "GE-Proton.*";
    releasePrefix = "GE-Proton";
    releaseSuffix = "";
    versionFilename = "ge-version.json";
    owner = "GloriousEggroll";
    repo = "proton-ge-custom";
  };

  pwvucontrol_git = callOverride ../pkgs/pwvucontrol-git {
    pwvucontrolPins = importJSON ../pkgs/pwvucontrol-git/pins.json;
  };

  wayland_git = callOverride ../pkgs/wayland-git { };
  wayland-protocols_git = callOverride ../pkgs/wayland-protocols-git { };
  wayland-scanner_git = prev.wayland-scanner.overrideAttrs (_: {
    inherit (final.wayland_git) src;
  });

  zfs_cachyos = cachyosPackages.zfs;
}
