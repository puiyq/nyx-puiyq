{
  inputs = {
    chaotic.url = "../";
    compare-to.url = "../";
    yafas = {
      url = "github:UbiqueLambda/yafas";
      inputs.systems.url = "github:nix-systems/default";
      inputs.flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/=0.1.5.tar.gz";
    };
  };
  outputs =
    {
      chaotic,
      compare-to,
      systems,
      yafas,
      ...
    }:
    let
      inputs = chaotic.inputs // {
        self = final;
        inherit compare-to systems yafas;
      };
      final = chaotic // {
        schemas = import ./schemas { flakes = inputs; };
        devShells = import ./dev-shells { flakes = inputs; };
        _dev = import ./dev {
          flakes = inputs;
          inherit (chaotic) nixConfig utils;
        };
      };
    in
    final;
}
