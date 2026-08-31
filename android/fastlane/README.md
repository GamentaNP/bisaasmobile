fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android beta

```sh
[bundle exec] fastlane android beta
```

Build and push to Play Internal (beta)

### android upload_only

```sh
[bundle exec] fastlane android upload_only
```

Upload pre-built AAB to Play Internal (skips Flutter build)

### android prod

```sh
[bundle exec] fastlane android prod
```

Promote internal -> production ( staged rollout 10% )

### android bump

```sh
[bundle exec] fastlane android bump
```

Bump versionCode / versionName from pubspec

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
