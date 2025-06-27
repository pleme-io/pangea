## Pangea CLI

The `lib/pangea/cli` directory contains the implementation of the Pangea command-line interface (CLI). It is responsible for parsing command-line arguments, executing the corresponding logic, and providing help and usage information to the user.

### Key Components:

- **`main.rb`**: This is the entry point for the CLI. It uses the `tty-option` gem to parse command-line arguments and then delegates to the appropriate subcommand.

- **`pangea.rb`**: This file defines the base `PangeaCommand` class, which provides common functionality for all Pangea commands, such as the `--help` and `--version` flags.

- **`config.rb`**: This file contains the logic for loading and resolving Pangea's configuration. It searches for configuration files in standard locations (e.g., `/etc/pangea`, `~/.config/pangea`, and the current directory) and merges them into a single configuration hash.

- **`constants.rb`**: This file defines various constants used throughout the CLI, such as file extensions, directory names, and project source directories.

### Subcommands:

The `lib/pangea/cli/subcommands` directory contains the implementation of the various subcommands supported by the Pangea CLI.

- **`config.rb`**: Implements the `pangea config` subcommand, which is used to manage Pangea's configuration. It provides functionality for showing the current configuration, planning configuration changes, and initializing the configuration.

- **`infra.rb`**: Implements the `pangea infra` subcommand, which is used to manage infrastructure. It provides functionality for planning and applying infrastructure changes.

- **`state.rb`**: Implements the `pangea state` subcommand, which is used to manage infrastructure state.
