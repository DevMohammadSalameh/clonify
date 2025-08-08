# Agent Guidelines for Clonify Repository

This document outlines the conventions and commands for agents operating within the Clonify codebase.

## 1. Build, Lint, and Test Commands

*   **Install Dependencies:** `dart pub get`
*   **Run All Tests:** `dart test`
*   **Run a Single Test:** `dart test <path_to_test_file> --name "<test_description>"`
    *   Example: `dart test test/clonify_test.dart --name "returns true for valid settings"`
*   **Run Linter:** `dart analyze`
*   **Format Code:** `dart format .`
*   **Build Executable:** `dart compile exe bin/clonify.dart`

## 2. Code Style Guidelines

*   **Formatting:** Adhere strictly to `dart format .` for consistent code style.
*   **Linting:** Follow all rules specified in `analysis_options.yaml` (based on `package:lints/recommended.yaml`).
*   **Naming Conventions:**
    *   Classes, Enums, Type Definitions: `PascalCase` (e.g., `ClonifySettings`).
    *   Functions, Variables, Parameters: `camelCase` (e.g., `initClonify`, `companyName`).
    *   Files: `snake_case` (e.g., `clonify_core.dart`).
*   **Imports:** Organize imports into `dart:`, `package:`, and relative paths, each group separated by a blank line.
*   **Typing:** Use explicit type declarations for clarity and maintainability.
*   **Error Handling:** Utilize `try-catch` blocks for anticipated errors. Define and throw custom exceptions for specific, recoverable error scenarios.
