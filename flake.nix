{
  description = "waasabi-live";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable-small";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.napalm.url = "github:nix-community/napalm";

  outputs = { self, nixpkgs, flake-utils, napalm }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ napalm.overlay self.overlay ]; };
        in
        {
          packages = {
            inherit (pkgs) waasabi-live;
          };
        }) // {
      overlay = final: prev: {
        waasabi-live = (final.napalm.buildPackage ./. {
          patchPhase = ''
            patchShebangs --build ./scripts
          '';
        });
      };
    };
}
