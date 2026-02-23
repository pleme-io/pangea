{
  description = "cloud provisioner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ruby-nix.url = "github:inscapist/ruby-nix";
    flake-utils.url = "github:numtide/flake-utils";
    substrate = {
      url = "github:pleme-io/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    forge = {
      url = "github:pleme-io/forge";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.substrate.follows = "substrate";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ruby-nix,
    flake-utils,
    substrate,
    forge,
    ...
  }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux" "aarch64-darwin"] (system: let
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

      # Substrate ruby build helpers (regen, Docker images, push via forge)
      rubyBuild = import "${substrate}/lib/ruby-build.nix" {
        inherit pkgs;
        forgeCmd = "${forge.packages.${system}.default}/bin/forge";
        defaultGhcrToken = "";
      };

      # ── Rspec test helpers ───────────────────────────────────────────────
      rspecGemIncludes = gems: builtins.concatStringsSep " " (map (p: "-I${env}/lib/ruby/gems/3.3.0/gems/${p}-*/lib") gems);

      rspecBaseGems = [
        "rspec-core" "rspec-support" "rspec-expectations" "rspec-mocks"
        "diff-lcs" "terraform-synthesizer" "abstract-synthesizer"
        "dry-types" "dry-struct" "dry-core" "dry-logic" "dry-inflector"
        "ice_nine" "concurrent-ruby" "psych"
      ];

      rspecCoverageGems = [
        "simplecov" "simplecov-html" "simplecov_json_formatter"
        "simplecov-lcov" "docile"
      ];

      rspecCmd = { srcLib, gems ? rspecBaseGems, testArgs }: ''
        ${ruby}/bin/ruby \
          ${rspecGemIncludes gems} \
          -I${srcLib} \
          ${env}/lib/ruby/gems/3.3.0/gems/rspec-core-*/exe/rspec \
          ${testArgs} \
          --format documentation \
          --color \
          --order defined
      '';

      # ── Pangea CLI package ──────────────────────────────────────────────
      pangeaPackage = pkgs.stdenv.mkDerivation {
        pname = "pangea";
        version = "1.0.0";
        src = ./.;
        buildInputs = [env ruby];
        installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/lib

          # Copy gem environment
          cp -r ${env}/lib/* $out/lib/

          # Copy pangea source code to lib
          cp -r $src/lib/* $out/lib/

          # Create a wrapper script that sets up the Ruby environment
          cat > $out/bin/pangea <<EOF
          #!${ruby}/bin/ruby
          # Suppress dry-types warnings about mutable defaults
          ENV['DRY_TYPES_WARNINGS'] = 'false'

          # Disable Zeitwerk's kernel require hook before loading dry-rb gems
          # This prevents Zeitwerk from intercepting our requires and causing
          # class/module mismatch errors with the lib directory structure
          module Zeitwerk
            module Kernel
              def self.extended(base)
                # Don't patch Kernel#require
              end
            end
          end

          \$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
          require 'pangea/cli/application'
          Pangea::CLI::Application.new.run
          EOF

          chmod +x $out/bin/pangea
        '';
      };

      # ── Pangea Compiler package ─────────────────────────────────────────
      pangeaCompilerPackage = pkgs.stdenv.mkDerivation {
        pname = "pangea-compiler";
        version = "1.0.0";
        src = ./.;
        buildInputs = [env ruby];
        installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/lib

          # Copy gem environment
          cp -r ${env}/lib/* $out/lib/

          # Copy pangea source code to lib
          cp -r $src/lib/* $out/lib/

          # Create compiler server wrapper
          cat > $out/bin/pangea-compiler <<EOF
          #!${ruby}/bin/ruby
          ENV['DRY_TYPES_WARNINGS'] = 'false'
          \$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
          require 'pangea/compiler_server'
          server = Pangea::CompilerServer.new
          server.start
          EOF

          chmod +x $out/bin/pangea-compiler
        '';
      };

      # ── Compiler server package (HTTP sidecar for pangea-operator) ──────
      compilerServer = pkgs.stdenv.mkDerivation {
        pname = "pangea-compiler-server";
        version = "1.0.0";
        src = ./.;
        buildInputs = [env ruby];
        installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/lib

          # Copy gem environment
          cp -r ${env}/lib/* $out/lib/

          # Copy pangea source code to lib
          cp -r $src/lib/* $out/lib/

          # Create wrapper script for compiler server
          cat > $out/bin/pangea-compiler-server <<EOF
          #!${ruby}/bin/ruby
          # Suppress dry-types warnings
          ENV['DRY_TYPES_WARNINGS'] = 'false'
          \$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
          load '${./.}/bin/pangea-compiler-server'
          EOF

          chmod +x $out/bin/pangea-compiler-server
        '';
      };

      # ── Synthesizer test suite ──────────────────────────────────────────
      synthesizerTests = pkgs.stdenv.mkDerivation {
        pname = "pangea-synthesizer-tests";
        version = "1.0.0";
        src = ./.;
        buildInputs = [env ruby];

        buildPhase = ''
          export HOME=$(mktemp -d)
          export DRY_TYPES_WARNINGS=false

          echo "Running Pangea Synthesizer Tests"
          echo "===================================="
          echo ""

          # Read YAML configuration to determine which tests to run
          TEST_FILES=$(${ruby}/bin/ruby \
            -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib \
            -ryaml \
            -e "
            src_dir = '$src'
            config_file = \"#{src_dir}/synthesizer-tests.yaml\"

            if File.exist?(config_file)
              config = YAML.load_file(config_file)
              mode = config['mode'] || 'all'

              case mode
              when 'enabled_only'
                enabled = config['enabled_tests'] || []
                if enabled.empty?
                  puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
                else
                  files = enabled.map { |f| \"#{src_dir}/spec/resources/#{f}\" }
                  puts files.join(' ')
                end
              when 'disabled_excluded'
                puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
              else
                puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
              end
            else
              puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
            end
          ")

          echo "Test configuration mode: $(${ruby}/bin/ruby -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib -ryaml -e "puts YAML.load_file('$src/synthesizer-tests.yaml')['mode'] rescue 'all'")"
          echo ""

          # Run rspec directly without bundler (avoids gemspec evaluation)
          if [[ "$TEST_FILES" == *"*"* ]]; then
            ${rspecCmd { srcLib = "$src/lib"; testArgs = ''--pattern "$TEST_FILES"''; }}
          else
            ${rspecCmd { srcLib = "$src/lib"; testArgs = "$TEST_FILES"; }}
          fi
        '';

        installPhase = ''
          mkdir -p $out
          echo "All synthesizer tests passed" > $out/result.txt
        '';

        checkPhase = "true"; # Tests run in buildPhase
      };

      # ── Docker images (via substrate mkRubyDockerImage) ─────────────────

      # CLI image — includes opentofu, git, awscli2 for provisioning
      dockerImage = rubyBuild.mkRubyDockerImage {
        rubyPackage = pangeaPackage;
        rubyEnv = env;
        inherit ruby;
        name = "ghcr.io/pleme-io/pangea";
        cmd = ["${pangeaPackage}/bin/pangea"];
        workingDir = "/workspace";
        env = [
          "PATH=/bin:/usr/bin"
        ];
        extraContents = with pkgs; [
          opentofu
          git
          awscli2
          tzdata
          bash
          skopeo
        ];
      };

      # Compiler sidecar image — HTTP server for Ruby DSL compilation
      compilerImage = rubyBuild.mkRubyDockerImage {
        rubyPackage = compilerServer;
        rubyEnv = env;
        inherit ruby;
        name = "ghcr.io/pleme-io/nexus/pangea-compiler";
        cmd = ["${compilerServer}/bin/pangea-compiler-server"];
        env = [
          "COMPILER_PORT=8082"
          "COMPILER_HOST=0.0.0.0"
        ];
        extraContents = with pkgs; [
          tzdata
          bash
        ];
        exposedPorts = {"8082/tcp" = {};};
      };

    in {
      packages = {
        default = pangeaPackage;
        pangea = pangeaPackage;
        pangea-compiler = pangeaCompilerPackage;
        synthesizer-tests = synthesizerTests;
        compiler-server = compilerServer;
        inherit env ruby dockerImage compilerImage;
      };

      devShells = rec {
        default = dev;
        dev = pkgs.mkShell {
          buildInputs = with pkgs; [env ruby opentofu git awscli2];
          shellHook = ''
            PATH=$PWD/bin:$PATH
            export RUBYLIB=$PWD/lib:$RUBYLIB
            export DRY_TYPES_WARNINGS=false
          '';
        };
      };

      apps = {
        default = {
          type = "app";
          program = "${pangeaPackage}/bin/pangea";
        };

        # Regenerate Gemfile.lock + gemset.nix
        regen = rubyBuild.mkRubyRegenApp {
          srcDir = self;
          name = "pangea";
        };

        # Push CLI image via forge
        "push:pangea" = rubyBuild.mkRubyPushApp {
          flakePath = self;
          imageOutput = "dockerImage";
          registry = "ghcr.io/pleme-io/pangea";
          name = "pangea";
        };

        # Push compiler image via forge
        "push:compiler" = rubyBuild.mkRubyPushApp {
          flakePath = self;
          imageOutput = "compilerImage";
          registry = "ghcr.io/pleme-io/nexus/pangea-compiler";
          name = "pangea-compiler";
        };

        # Full release — regen + push both images
        release = {
          type = "app";
          program = toString (pkgs.writeShellScript "release-pangea" ''
            set -euo pipefail
            echo "Releasing Pangea..."
            echo ""
            nix run .#regen
            echo ""
            nix run .#push:pangea
            echo ""
            nix run .#push:compiler
            echo ""
            echo "Release complete!"
          '');
        };

        # Build Docker image
        build = {
          type = "app";
          program = toString (pkgs.writeShellScript "build-pangea" ''
            set -euo pipefail
            echo "Building Pangea Docker image..."
            nix build .#dockerImage
            echo "Build complete"
            echo "Image built: result"
          '');
        };

        # Load image into Docker daemon
        load = {
          type = "app";
          program = toString (pkgs.writeShellScript "load-pangea" ''
            set -euo pipefail
            echo "Loading Pangea image into Docker..."

            if ! command -v docker &> /dev/null; then
              echo "Error: docker command not found"
              exit 1
            fi

            echo "Building image..."
            nix build .#dockerImage
            docker load < result

            echo "Pangea image loaded into Docker"
            echo ""
            echo "Run with: docker run --rm ghcr.io/pleme-io/pangea:latest --help"
          '');
        };

        # Run all tests
        test = {
          type = "app";
          program = toString (pkgs.writeShellScript "test-pangea" ''
            set -euo pipefail
            cd ${./.}
            echo "Running Pangea tests..."
            ${ruby}/bin/bundle install
            ${ruby}/bin/bundle exec rspec --format documentation
          '');
        };

        # Build .gem file via forge
        "gem:build" = rubyBuild.mkRubyGemBuildApp {
          srcDir = self;
          name = "pangea";
        };

        # Push gem to RubyGems.org via forge
        "gem:push" = rubyBuild.mkRubyGemPushApp {
          srcDir = self;
          name = "pangea";
        };

        # Run synthesizer tests only (Nix-built, reproducible)
        synthesizer-tests = {
          type = "app";
          program = toString (pkgs.writeShellScript "synthesizer-tests" ''
            set -euo pipefail

            export HOME=$(mktemp -d)
            export DRY_TYPES_WARNINGS=false

            echo "Pangea Synthesizer Test Suite"
            echo "=================================="
            echo ""

            # Read YAML configuration to determine which tests to run
            TEST_FILES=$(${ruby}/bin/ruby \
              -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib \
              -ryaml \
              -e "
              src_dir = '${./.}'
              config_file = \"#{src_dir}/synthesizer-tests.yaml\"

              if File.exist?(config_file)
                config = YAML.load_file(config_file)
                mode = config['mode'] || 'all'

                case mode
                when 'enabled_only'
                  enabled = config['enabled_tests'] || []
                  if enabled.empty?
                    puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
                  else
                    files = enabled.map { |f| \"#{src_dir}/spec/resources/#{f}\" }
                    puts files.join(' ')
                  end
                when 'disabled_excluded'
                  puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
                else
                  puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
                end
              else
                puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
              end
            ")

            MODE=$(${ruby}/bin/ruby -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib -ryaml -e "puts YAML.load_file('${./.}/synthesizer-tests.yaml')['mode'] rescue 'all'")
            echo "Test configuration mode: $MODE"
            echo ""

            if [[ "$TEST_FILES" == *"*"* ]]; then
              ${rspecCmd { srcLib = "${./.}/lib"; gems = rspecBaseGems ++ rspecCoverageGems; testArgs = ''--pattern "$TEST_FILES"''; }}
            else
              ${rspecCmd { srcLib = "${./.}/lib"; gems = rspecBaseGems ++ rspecCoverageGems; testArgs = "$TEST_FILES"; }}
            fi

            echo ""
            echo "All synthesizer tests passed!"
          '');
        };
      };
    });
}
