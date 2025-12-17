{
  flakes,
  nixConfig,
  utils,
  self ? flakes.self,
}:
flakes.yafas.withAllSystems { }
  (
    universals:
    { system, ... }:
    let
      nixPkgsConfig = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        nvidia.acceptLicense = true;
      };
      nixPkgs = import flakes.nixpkgs {
        inherit system;
        config = nixPkgsConfig;
      };
      nyxPkgs = utils.applyOverlay { pkgs = nixPkgs; };
    in
    with universals;
    {
      legacyPackages = nyxPkgs;
      nixpkgs = nixPkgs;
      mergedPkgs = utils.applyOverlay {
        pkgs = nixPkgs;
        merge = true;
        replace = true;
      };
      system = flakes.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.default
          { boot.isContainer = true; }
        ];
      };
    }
  )
  {
    inherit nixConfig;
  }
