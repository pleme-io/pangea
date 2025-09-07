# Contributing to Pangea

First off, thank you for considering contributing to Pangea! It's people like you that make Pangea such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by the [Pangea Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps which reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps**
* **Explain which behavior you expected to see instead and why**
* **Include details about your configuration and environment**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a step-by-step description of the suggested enhancement**
* **Provide specific examples to demonstrate the steps**
* **Describe the current behavior and explain which behavior you expected to see instead**
* **Explain why this enhancement would be useful**

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the Ruby style guide
* Include thoughtfully-worded, well-structured tests
* Document new code with YARD comments
* End all files with a newline

## Development Setup

1. Fork and clone the repo
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Make sure tests pass:
   ```bash
   bundle exec rake spec
   ```
4. Create a branch:
   ```bash
   git checkout -b my-feature-branch
   ```
5. Make your changes and add tests
6. Run the test suite:
   ```bash
   bundle exec rake spec
   ```
7. Run type checking:
   ```bash
   bundle exec steep check
   ```
8. Run linting:
   ```bash
   bundle exec rubocop
   ```

## Testing

* Write RSpec tests for any new functionality
* Ensure all tests pass before submitting PR
* Aim for high test coverage (80%+)
* Include both unit and integration tests where appropriate

### Running Tests

```bash
# Run all tests
bundle exec rake spec

# Run specific test file
bundle exec rspec spec/path/to/spec.rb

# Run with coverage
bundle exec rake coverage
```

## Type Checking

Pangea uses RBS for type definitions and Steep for type checking:

```bash
# Check types
bundle exec steep check

# Generate RBS signatures
bundle exec rbs prototype rb lib/pangea/new_file.rb > sig/pangea/new_file.rbs
```

## Style Guidelines

### Ruby Style

* Follow the community Ruby style guide
* Use RuboCop for style checking
* Prefer functional style where appropriate
* Use descriptive variable names
* Keep methods small and focused

### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

### Documentation

* Use YARD for API documentation
* Update README.md with details of changes to the interface
* Create or update example files in the `examples/` directory
* Document complex logic with inline comments

## Project Structure

```
pangea/
├── lib/           # Main library code
├── spec/          # RSpec tests
├── examples/      # Example templates
├── sig/           # RBS type signatures
└── docs/          # Additional documentation
```

## Release Process

Releases are automated via GitHub Actions when a new tag is pushed. Only maintainers can create releases.

## Questions?

Feel free to open an issue with your question or reach out to the maintainers directly.