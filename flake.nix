{
  description = "cloud renderer, world creator";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.ruby-nix.url = "github:inscapist/ruby-nix";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    nixpkgs,
    flake-utils,
    ruby-nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ruby-nix.overlays.ruby];
      };
      rnix = ruby-nix.lib pkgs;
      rnix-env = rnix {
        name = "pangea";
        gemset = ./gemset.nix;
      };
      env = rnix-env.env;
      ruby = rnix-env.ruby;
    in {
      devShells = rec {
        default = dev;
        dev = pkgs.mkShell {
          buildInputs = [
            env
            ruby
          ];
        };
      };

      # Here we add a package derivation for the built binary:
      packages = {
        inherit env;
        pangea = pkgs.stdenv.mkDerivation {
          pname = "pangea";
          version = "0.1.0";
          # Assume your project root (including bin/, lib/, etc.) is the source
          src = ./.;
          buildInputs = [env ruby pkgs.makeWrapper];

          # Optionally, if your build process is more elaborate you can invoke
          # a build command (e.g. via rake). For a simple CLI, if your binary
          # is already present in bin/pangea (or built via a small script),
          # you may simply install it.
          buildPhase = ''
            echo "Building pangea binary"
            # For example, you might run:
            # bundle exec rake build
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp bin/pangea $out/bin/
            chmod +x $out/bin/pangea
            # Optionally wrap the binary so that the Ruby interpreter is in PATH:
            wrapProgram $out/bin/pangea --prefix PATH : "${ruby}/bin"
          '';

          meta = with pkgs.lib; {
            description = "Pangea CLI built with a ruby-nix gem environment";
            homepage = "https://github.com/your-org/pangea";
            license = licenses.mit;
            maintainers = ["your-name"];
          };
        };
      };
    });
}
