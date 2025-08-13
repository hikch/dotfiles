{
  description = "Gemini CLI packaged for Nix/Devbox (local flake).";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
  in
  {
    packages = forAllSystems (pkgs:
      let
        node = pkgs.nodejs_18;
        # NOTE: Pin the version and tarball hash here
        geminiVersion = "0.1.20";  # <== bump with update script
        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${geminiVersion}.tgz";
          sha256 = "sha256-0ZaKl1t3sT3vfkPZ8ZT9I/yPIWSrLLKlMkXWLOrbRi0="; # <== replace via update script
        };
      in
      {
        gemini-cli = pkgs.stdenv.mkDerivation {
          pname = "gemini-cli";
          version = geminiVersion;
          nativeBuildInputs = [ node pkgs.makeWrapper ];
          unpackPhase = "true";
          installPhase = ''
            mkdir -p $out
            export HOME=$TMPDIR
            # npm installs into $out, producing $out/bin/gemini
            npm install -g --offline --prefix=$out ${src}
            # Ensure node is on PATH when running the binary
            wrapProgram $out/bin/gemini --prefix PATH : ${node}/bin
          '';
          # Don't try to run tests
          doCheck = false;
          meta = with pkgs.lib; {
            description = "Google Gemini CLI packaged via Nix";
            homepage = "https://github.com/google-gemini/gemini-cli";
            platforms = platforms.all;
            license = licenses.asl20;
          };
        };
        default = pkgs.symlinkJoin {
          name = "gemini-cli-env";
          paths = [ pkgs.nodejs_18 (pkgs.writeShellScriptBin "gemini" ''exec "${self.packages.${pkgs.system}.gemini-cli}/bin/gemini" "$@"'') ];
        };
      });

    # 'nix develop' gives you a shell with the CLI on PATH
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = [ self.packages.${pkgs.system}.gemini-cli ];
      };
    });

    # For 'nix run .#gemini-cli'
    apps = forAllSystems (pkgs: {
      gemini-cli = {
        type = "app";
        program = "${self.packages.${pkgs.system}.gemini-cli}/bin/gemini";
      };
      default = self.apps.${pkgs.system}.gemini-cli;
    });
  };
}