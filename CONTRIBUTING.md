# Contributing to Clonify

First off, thank you for considering contributing to Clonify! It's people like you that make Clonify such a great tool.

## Where do I go from here?

If you've noticed a bug or have a feature request, [make one](https://github.com/DevMohammadSalameh/clonify/issues/new)! It's generally best if you get confirmation of your bug or approval for your feature request this way before starting to code.

### Fork & create a branch

If this is something you think you can fix, then [fork Clonify](https://github.com/DevMohammadSalameh/clonify/fork) and create a branch with a descriptive name.

A good branch name would be (where issue #123 is the ticket you're working on):

```sh
git checkout -b 123-add-a-new-feature
```

### Get the project running

This is a Dart CLI project. You should have the Dart SDK installed.

1.  Clone your fork of the repository.
2.  Run `dart pub get` to install dependencies.
3.  The main entry point is `bin/clonify.dart`. You can run it with `dart run bin/clonify.dart <command>`.

### Make your changes

Make your changes to the codebase.

Make sure to add tests for your changes. The tests are in the `test/` directory. You can run the tests with the `dart test` command.

### Linting and Formatting

This project uses `lints` for linting and `dart format` for formatting. Please make sure your code is formatted and that there are no linter warnings before submitting a pull request.

-   To format the code, run: `dart format .`
-   To analyze the code, run: `dart analyze`

### Commit your changes

Make sure your commit messages are descriptive.

### Pull Request

When you're done with the changes, create a pull request. Make sure to link the issue you're fixing in the pull request description.

## Code of Conduct

This project has a [Code of Conduct](CODE_OF_CONDUCT.md) that all contributors are expected to follow.

## Styleguide

This project follows the [Effective Dart](https://dart.dev/effective-dart) styleguide.
