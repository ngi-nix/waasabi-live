{
  description = "waasabi-live";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable-small";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
        in
        {
          packages = {
            inherit (pkgs) esbuild;
          };
        }) // {
      overlay = final: prev: {
        esbuild = prev.esbuild.overrideAttrs (oldAttrs: rec {
          version = "0.12.9";

          src = final.fetchFromGitHub {
            owner = "evanw";
            repo = "esbuild";
            rev = "v${version}";
            sha256 = "sha256-MqwgdhgWIfYE0wO7fWQuC72tEwCVgL7qUbJlJ3APf4E=";
          };
        });
      };
    };
}
