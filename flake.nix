{
  description = "cloud provisioner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ruby-nix.url = "github:inscapist/ruby-nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    ruby-nix,
    flake-utils,
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

      # Build Pangea CLI package
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

      # Build Pangea Compiler Server package
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

      # Build synthesizer test suite
      synthesizerTests = pkgs.stdenv.mkDerivation {
        pname = "pangea-synthesizer-tests";
        version = "1.0.0";
        src = ./.;
        buildInputs = [env ruby];

        buildPhase = ''
          export HOME=$(mktemp -d)
          export DRY_TYPES_WARNINGS=false

          echo "🧪 Running Pangea Synthesizer Tests"
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
                # This would require globbing all files and excluding some
                # For now, default to all
                puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
              else
                # mode == 'all' or unrecognized
                puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
              end
            else
              # No config file, run all tests
              puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
            end
          ")

          echo "Test configuration mode: $(${ruby}/bin/ruby -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib -ryaml -e "puts YAML.load_file('$src/synthesizer-tests.yaml')['mode'] rescue 'all'")"
          echo ""

          # Run rspec directly without bundler (avoids gemspec evaluation)
          # Use either --pattern for globs or explicit file list
          if [[ "$TEST_FILES" == *"*"* ]]; then
            # Pattern mode
            ${ruby}/bin/ruby \
              -I${env}/lib/ruby/gems/3.3.0/gems/rspec-core-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/rspec-support-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/rspec-expectations-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/rspec-mocks-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/diff-lcs-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/terraform-synthesizer-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/abstract-synthesizer-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-types-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-struct-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-core-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-logic-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-inflector-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/ice_nine-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/concurrent-ruby-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib \
              -I$src/lib \
              ${env}/lib/ruby/gems/3.3.0/gems/rspec-core-*/exe/rspec \
              --pattern "$TEST_FILES" \
              --format documentation \
              --color \
              --order defined
          else
            # Explicit file list mode
            ${ruby}/bin/ruby \
              -I${env}/lib/ruby/gems/3.3.0/gems/rspec-core-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/rspec-support-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/rspec-expectations-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/rspec-mocks-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/diff-lcs-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/terraform-synthesizer-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/abstract-synthesizer-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-types-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-struct-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-core-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-logic-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/dry-inflector-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/ice_nine-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/concurrent-ruby-*/lib \
              -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib \
              -I$src/lib \
              ${env}/lib/ruby/gems/3.3.0/gems/rspec-core-*/exe/rspec \
              $TEST_FILES \
              --format documentation \
              --color \
              --order defined
          fi
        '';

        installPhase = ''
          mkdir -p $out
          echo "✅ All synthesizer tests passed" > $out/result.txt

          # Read configuration for report
          MODE=$(${ruby}/bin/ruby -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib -ryaml -e "puts YAML.load_file('$src/synthesizer-tests.yaml')['mode'] rescue 'all'")

          # Get list of enabled tests for display
          ENABLED_TESTS=$(${ruby}/bin/ruby -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib -ryaml -e "
            config = YAML.load_file('$src/synthesizer-tests.yaml') rescue {}
            enabled = config['enabled_tests'] || []
            if enabled.empty?
              puts 'All tests'
            else
              enabled.each { |t| puts \"  - #{t}\" }
            end
          ")

          # Create test report
          cat > $out/test-report.txt <<EOF
          Pangea Synthesizer Test Suite
          ==============================

          Test Type: Resource Synthesis Tests
          Configuration: synthesizer-tests.yaml
          Mode: $MODE

          Tests configured:
          $ENABLED_TESTS

          All tests validate:
          ✓ terraform-synthesizer integration
          ✓ Correct Terraform JSON generation
          ✓ Resource references and interpolation
          ✓ Type validation via Dry::Struct
          ✓ Default values in Terraform output
          ✓ Optional field omission
          ✓ Nested blocks and arrays
          ✓ Resource composition

          Build completed: $(date)

          To run all tests, set mode: all in synthesizer-tests.yaml
          To run specific tests, set mode: enabled_only and list tests in enabled_tests
          EOF
        '';

        checkPhase = "true"; # Tests run in buildPhase
      };

      # Build Docker image for local architecture (amd64) - CLI
      dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "ghcr.io/pleme-io/pangea";
        tag = "latest";

        contents = [
          pangeaPackage
          env
          ruby
          pkgs.opentofu
          pkgs.git
          pkgs.awscli2
          pkgs.cacert
          pkgs.tzdata
          pkgs.coreutils
          pkgs.bash
          pkgs.skopeo # For pushing to registry
        ];

        config = {
          Cmd = ["${pangeaPackage}/bin/pangea"];
          WorkingDir = "/workspace";
          Env = [
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            "DRY_TYPES_WARNINGS=false"
            "PATH=/bin:/usr/bin"
          ];
        };

        extraCommands = ''
          mkdir -p workspace tmp
          mkdir -p etc
          echo "pangea:x:1000:1000::/workspace:/bin/bash" > etc/passwd
          echo "pangea:x:1000:" > etc/group
        '';
      };

      # Build compiler server package (HTTP sidecar for pangea-operator)
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

      # Docker image for compiler sidecar (WEBrick HTTP server)
      # Used by pangea-operator as a sidecar for compiling Ruby DSL to Terraform JSON
      compilerImage = pkgs.dockerTools.buildLayeredImage {
        name = "ghcr.io/pleme-io/nexus/pangea-compiler";
        tag = "latest";

        contents = [
          compilerServer
          env
          ruby
          pkgs.cacert
          pkgs.tzdata
          pkgs.coreutils
          pkgs.bash
        ];

        config = {
          Cmd = ["${compilerServer}/bin/pangea-compiler-server"];
          WorkingDir = "/";
          Env = [
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            "DRY_TYPES_WARNINGS=false"
            "COMPILER_PORT=8082"
            "COMPILER_HOST=0.0.0.0"
          ];
          ExposedPorts = {"8082/tcp" = {};};
        };

        extraCommands = ''
          mkdir -p tmp
          mkdir -p etc
          echo "compiler:x:1000:1000::/:/bin/bash" > etc/passwd
          echo "compiler:x:1000:" > etc/group
        '';
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

        # Build Docker image (amd64 only)
        build = {
          type = "app";
          program = toString (pkgs.writeShellScript "build-pangea" ''
            set -euo pipefail
            echo "Building Pangea Docker image..."
            nix build .#dockerImage
            echo "✅ Build complete"
            echo ""
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

            # Build and load image
            echo "Building image..."
            nix build .#dockerImage
            docker load < result

            echo "✅ Pangea image loaded into Docker"
            echo ""
            echo "Run with: docker run --rm ghcr.io/pleme-io/pangea:latest --help"
          '');
        };

        # Push image to GitHub Container Registry using skopeo
        push = {
          type = "app";
          program = toString (pkgs.writeShellScript "push-pangea" ''
            set -euo pipefail

            # Get GHCR token (follows repo standard)
            GHCR_TOKEN="''${GHCR_TOKEN:-''${GITHUB_TOKEN:-}}"
            if [ -z "$GHCR_TOKEN" ]; then
              echo "Error: GHCR_TOKEN or GITHUB_TOKEN environment variable is required"
              echo "Set it with: export GHCR_TOKEN=ghp_your_token"
              exit 1
            fi

            # Get git commit SHA for tagging (10-char hash for consistency with services)
            GIT_SHA=$(git rev-parse --short=10 HEAD 2>/dev/null || echo "dev")
            REGISTRY="ghcr.io/pleme-io/pangea"

            echo "📦 Pushing Pangea to $REGISTRY"
            echo "🏷️  Tags: amd64-$GIT_SHA, latest"
            echo ""

            # Build image
            echo "Building Docker image..."
            nix build .#dockerImage

            # Push with architecture-specific tag (standardized format)
            echo "Pushing amd64-$GIT_SHA..."
            ${pkgs.skopeo}/bin/skopeo copy \
              --insecure-policy \
              --retry-times=10 \
              --dest-creds=pleme-io:$GHCR_TOKEN \
              docker-archive:./result \
              docker://$REGISTRY:amd64-$GIT_SHA

            # Also tag as latest
            echo "Tagging as latest..."
            ${pkgs.skopeo}/bin/skopeo copy \
              --insecure-policy \
              --retry-times=10 \
              --dest-creds=pleme-io:$GHCR_TOKEN \
              docker-archive:./result \
              docker://$REGISTRY:latest

            echo ""
            echo "✅ Pushed to $REGISTRY:amd64-$GIT_SHA"
            echo "✅ Tagged as $REGISTRY:latest"
          '');
        };

        # Push compiler image to GitHub Container Registry using skopeo
        push-compiler = {
          type = "app";
          program = toString (pkgs.writeShellScript "push-pangea-compiler" ''
            set -euo pipefail

            # Get GHCR token (follows repo standard)
            GHCR_TOKEN="''${GHCR_TOKEN:-''${GITHUB_TOKEN:-}}"
            if [ -z "$GHCR_TOKEN" ]; then
              echo "Error: GHCR_TOKEN or GITHUB_TOKEN environment variable is required"
              echo "Set it with: export GHCR_TOKEN=ghp_your_token"
              exit 1
            fi

            # Get git commit SHA for tagging (10-char hash for consistency with services)
            GIT_SHA=$(git rev-parse --short=10 HEAD 2>/dev/null || echo "dev")
            REGISTRY="ghcr.io/pleme-io/nexus/pangea-compiler"

            echo "📦 Pushing Pangea Compiler to $REGISTRY"
            echo "🏷️  Tags: amd64-$GIT_SHA, latest"
            echo ""

            # Build image
            echo "Building Docker image..."
            nix build .#compilerImage

            # Push with architecture-specific tag (standardized format)
            echo "Pushing amd64-$GIT_SHA..."
            ${pkgs.skopeo}/bin/skopeo copy \
              --insecure-policy \
              --retry-times=10 \
              --dest-creds=pleme-io:$GHCR_TOKEN \
              docker-archive:./result \
              docker://$REGISTRY:amd64-$GIT_SHA

            # Also tag as latest
            echo "Tagging as latest..."
            ${pkgs.skopeo}/bin/skopeo copy \
              --insecure-policy \
              --retry-times=10 \
              --dest-creds=pleme-io:$GHCR_TOKEN \
              docker-archive:./result \
              docker://$REGISTRY:latest

            echo ""
            echo "✅ Pushed to $REGISTRY:amd64-$GIT_SHA"
            echo "✅ Tagged as $REGISTRY:latest"
          '');
        };

        # Complete release workflow
        release = {
          type = "app";
          program = toString (pkgs.writeShellScript "release-pangea" ''
            set -euo pipefail
            echo "🚀 Releasing Pangea..."
            echo ""
            nix run .#build
            echo ""
            nix run .#push
            echo ""
            echo "✅ Release complete"
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

        # Run synthesizer tests only (Nix-built, reproducible)
        synthesizer-tests = {
          type = "app";
          program = toString (pkgs.writeShellScript "synthesizer-tests" ''
            set -euo pipefail

            export HOME=$(mktemp -d)
            export DRY_TYPES_WARNINGS=false

            echo "🧪 Pangea Synthesizer Test Suite"
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
                  # This would require globbing all files and excluding some
                  # For now, default to all
                  puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
                else
                  # mode == 'all' or unrecognized
                  puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
                end
              else
                # No config file, run all tests
                puts \"#{src_dir}/spec/resources/**/synthesis_spec.rb\"
              end
            ")

            MODE=$(${ruby}/bin/ruby -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib -ryaml -e "puts YAML.load_file('${./.}/synthesizer-tests.yaml')['mode'] rescue 'all'")
            echo "Test configuration mode: $MODE"
            echo ""

            # Run rspec directly without bundler (avoids gemspec evaluation)
            # Use either --pattern for globs or explicit file list
            if [[ "$TEST_FILES" == *"*"* ]]; then
              # Pattern mode
              ${ruby}/bin/ruby \
                -I${env}/lib/ruby/gems/3.3.0/gems/rspec-core-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/rspec-support-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/rspec-expectations-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/rspec-mocks-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/diff-lcs-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/terraform-synthesizer-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/abstract-synthesizer-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-types-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-struct-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-core-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-logic-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-inflector-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/ice_nine-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/concurrent-ruby-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/simplecov-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/simplecov-html-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/simplecov_json_formatter-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/simplecov-lcov-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/docile-*/lib \
                -I${./.}/lib \
                ${env}/lib/ruby/gems/3.3.0/gems/rspec-core-*/exe/rspec \
                --pattern "$TEST_FILES" \
                --format documentation \
                --color \
                --order defined
            else
              # Explicit file list mode
              ${ruby}/bin/ruby \
                -I${env}/lib/ruby/gems/3.3.0/gems/rspec-core-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/rspec-support-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/rspec-expectations-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/rspec-mocks-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/diff-lcs-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/terraform-synthesizer-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/abstract-synthesizer-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-types-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-struct-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-core-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-logic-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/dry-inflector-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/ice_nine-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/concurrent-ruby-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/psych-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/simplecov-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/simplecov-html-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/simplecov_json_formatter-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/simplecov-lcov-*/lib \
                -I${env}/lib/ruby/gems/3.3.0/gems/docile-*/lib \
                -I${./.}/lib \
                ${env}/lib/ruby/gems/3.3.0/gems/rspec-core-*/exe/rspec \
                $TEST_FILES \
                --format documentation \
                --color \
                --order defined
            fi

            echo ""
            echo "✅ All synthesizer tests passed!"
          '');
        };
      };
    });
}
