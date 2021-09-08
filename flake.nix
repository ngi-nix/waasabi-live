{
  description = "waasabi-live";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable-small";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };

          pin-deps = pkgs.writeShellScriptBin "pin-deps" ''
            ${pkgs.nodePackages.node2nix}/bin/node2nix -l package-lock.json -o nix/node-packages.nix -c nix/default.nix -e nix/node-env.nix
          '';
        in
        {
          packages = {
            inherit (pkgs) esbuild waasabi-live;
          };

          devShell = ((import ./nix { inherit pkgs system; nodejs = pkgs.nodejs-14_x; }).shell.override {
            buildPhase = ''
              mkdir -p esbuild/bin
              export XDG_CACHE_HOME=$PWD
              cp ${pkgs.esbuild}/bin/esbuild esbuild/bin/esbuild-linux-64@${pkgs.esbuild.version}
            '';
          }).overrideAttrs (oldAttrs: {
            buildInputs = oldAttrs.buildInputs ++ [ pin-deps ];
          });

          apps = {
            "pin-deps" = {
              type = "app";
              program = "${pin-deps}/bin/pin-deps";
            };
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

        waasabi-live = (import ./nix { pkgs = final; system = final.system; nodejs = final.nodejs-14_x; }).package.overrideAttrs(oldAttrs: rec {
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

          waasabiConfig = final.writeTextFile {
            name = "config.js";
            text = "
              export default {
                PREFIX: '',
                BUILD_DIR: '_site/',
                WAASABI_BRAND: 'placeholder',
                WAASABI_BACKEND: 'http://localhost',
                WAASABI_GRAPHQL_WS: 'wss://localhost/graphql',
                WAASABI_SESSION_URL: ' ',
                WAASABI_CHAT_ENABLED: true,
                WAASABI_CHAT_SYSTEM: 'matrix',
                WAASABI_CHAT_INVITES: false,
                WAASABI_CHAT_URL: 'https://matrix.to/',
                WAASABI_MATRIX_CLIENT: 'https://app.element.io/',
                WAASABI_MATRIX_API: 'https://matrix.org/_matrix/',
              }
            ";
          };

          postInstall = ''
            cp ${waasabiConfig} src/config.js
            npm run build
          '';
        });
      };
    };
}
