## Pangea Core Library

The `lib/pangea` directory contains the core logic for the Pangea application. It is responsible for processing Pangea configuration files, interacting with Terraform, and managing the application's state.

### Key Components:

- **`cli.rb`**: Implements the command-line interface (CLI) for Pangea using the `thor` gem. It defines commands like `apply`, `plan`, `show`, and `destroy`, which are essential for managing infrastructure.

- **`config.rb`**: Manages the application's configuration. It loads and merges YAML configuration files from different locations, allowing for a flexible and layered configuration approach.

- **`processor.rb`**: This is the heart of Pangea's processing logic. It reads and evaluates Pangea files, which are Ruby scripts that define infrastructure resources. It uses `terraform-synthesizer` to generate Terraform JSON configuration.

- **`renderer.rb`**: Responsible for rendering the generated Terraform JSON and applying it. It interacts with the `tofu` (OpenTofu) command-line tool to execute Terraform commands.

- **`state.rb`**: Manages the application's state. It supports both local and S3-based state management, including the creation of S3 buckets and DynamoDB tables for state locking.

- **`modules.rb`**: Provides functionality for handling Pangea modules. These modules are reusable units of Terraform code that can be shared and versioned.

- **`sandbox.rb`**: Implements a sandboxed environment for executing Pangea modules. This ensures that modules are executed in an isolated and controlled environment.

- **`shell.rb`**: A utility module for running shell commands and capturing their output.

- **`docker.rb`**: Provides a simple DSL for interacting with Docker and Docker Compose.

- **`utils.rb`**: A collection of utility functions used throughout the application.
