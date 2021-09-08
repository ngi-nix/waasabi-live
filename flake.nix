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
            inherit (pkgs) esbuild waasabi-live;
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

        waasabi-live = (import ./nix { pkgs = final; system = final.system; }).package.overrideAttrs(oldAttrs: {
          # https://github.com/evanw/esbuild/blob/master/lib/npm/install.ts#L15
          # The esbuild postinstall scripts installs the esbuild binary written in Go
          # However, it doesn't seem to pick it up from NPM (even when specified as dependency)
          # Luckily the install scripts looks in the cache directory first,
          # so we can simulate a cache by placing the binary in the correct place.
          # But this solution only works on linux build hosts, as a different path
          # is queried by the script under Windows and OSX.
          postPatch = ''
            mkdir -p esbuild/bin
            export XDG_CACHE_HOME=$PWD
            cp ${final.esbuild}/bin/esbuild esbuild/bin/esbuild-linux-64@${final.esbuild.version}
          '';
        });
      };
    };
}
