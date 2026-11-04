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

### android build

```sh
[bundle exec] fastlane android build
```

Build release AAB

### android deploy_internal

```sh
[bundle exec] fastlane android deploy_internal
```

Upload the built AAB to the internal track

### android promote

```sh
[bundle exec] fastlane android promote
```

Promote a release between tracks. Usage: promote from:internal to:beta [rollout:0.1]

### android rollout

```sh
[bundle exec] fastlane android rollout
```

Change the production staged-rollout percentage. Usage: rollout percent:0.5

### android halt

```sh
[bundle exec] fastlane android halt
```

Halt the current production staged rollout

### android pull_listing

```sh
[bundle exec] fastlane android pull_listing
```

Download the current store listing (texts, images, screenshots) into fastlane/metadata/android

### android push_listing

```sh
[bundle exec] fastlane android push_listing
```

Upload store listing. Options: text:true (texts only) | images:true (graphics + screenshots only)

### android metadata

```sh
[bundle exec] fastlane android metadata
```



### android versions

```sh
[bundle exec] fastlane android versions
```

Show versionCodes on every track

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
