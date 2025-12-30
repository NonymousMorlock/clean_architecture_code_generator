# Contributing to Clean Architecture Code Generator

First off, thank you for considering contributing to Clean Architecture Code Generator! It's people like you who make this tool better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Style Guide](#style-guide)

## Code of Conduct

By participating in this project, you are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md).

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to see if the problem has already been reported. When you are creating a bug report, please include as many details as possible:

*   **Use a clear and descriptive title** for the issue.
*   **Describe the exact steps which reproduce the problem** in as many details as possible.
*   **Describe the behavior you observed** after following the steps and explain precisely what is wrong with that behavior.
*   **Explain which behavior you expected to see instead and why.**
*   **Include code snippets** or a link to a repository that reproduces the issue.
*   **Provide details about your environment**, such as Flutter/Dart version, OS, and the generator version.

### Suggesting Enhancements

If you have an idea for a new feature or an improvement to an existing one, please open an issue with the following information:

*   **Use a clear and descriptive title.**
*   **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
*   **Explain why this enhancement would be useful** to most users.
*   **List some other libraries or tools where this feature exists**, if applicable.

### Pull Requests

1.  Fork the repo and create your branch from `main`.
2.  If you've added code that should be tested, add tests.
3.  Ensure the test suite passes.
4.  Make sure your code lints.
5.  Issue that pull request!

## Development Setup

The project is structured as a monorepo with the following packages:

*   `annotations/`: Contains the annotations used to mark classes for generation.
*   `generators/`: Contains the logic for the source-to-source generation.
*   `cli/`: Command-line interface for the tool.

### Setup Instructions

1.  Clone the repository.
2.  Install dependencies for all packages:
    ```bash
    cd annotations && dart pub get && cd ..
    cd generators && dart pub get && cd ..
    cd cli && dart pub get && cd ..
    ```
3.  To run the generator in the example project:
    ```bash
    cd example
    dart run build_runner build --delete-conflicting-outputs
    ```

## Style Guide

*   We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).
*   Use `dart format` to format your code.
*   Ensure all public APIs have documentation comments.
*   Commit messages should be clear and descriptive.

## Questions?

If you have any questions, feel free to open an issue or reach out to the maintainers.

Happy coding!
