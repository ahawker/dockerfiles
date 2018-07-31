# Dockerfiles

[![Build Status](https://travis-ci.org/ahawker/dockerfiles.svg?branch=master)](https://travis-ci.org/ahawker/dockerfiles)

Build a common set of images from Dockerfiles.

## Status

Core functionality is in place. See the `TODO` section below for open thoughts/items.

## Goals

Automate the process of building structured images from Dockerfiles that are tagged/linked together.

## Related

See [Dotfiles](https://github.com/ahawker/dotfiles) for bringing these into your shell environment.

## Usage

### End User

If you're an end user, you should consume the images from the configured image registry that are uploaded there as part of the CI/CD process.

By default, these are located [here](https://hub.docker.com/u/ahawker/) on `Dockerhub` and are deployed automatically via [Travis CI](https://travis-ci.org/ahawker/dockerfiles).

### Development

If you're a developer working on this repository, here's some hints to hopefully guide you through the process.

**Usage**

All `Makefile` should support `make help` to display their usage and have `help` set as their default goal.

```bash
$ make
all                            Run recursive 'make all' to build an deploy all images.
build                          Run recursive 'make build' to build all images.
clean                          Run recursive 'make clean' to clean all images.
deploy                         Run recursive 'make deploy' to deploy all images.
test                           Run recursive 'make test' to test all images.
help                           Print Makefile usage.
```

While not visible in the `help` output, the main `Makefile` supports recursive target generation. This enables invoking targets on the `Makefile` defined in subdirectories.

For example, let's access the `alpine` image.

```bash
$ make alpine
all                            Run recursive 'make all' to build an deploy all images.
build                          Run recursive 'make build' to build all images.
clean                          Run recursive 'make clean' to clean all images.
deploy                         Run recursive 'make deploy' to deploy all images.
test                           Run recursive 'make test' to test all images.
help                           Print Makefile usage.
```

Hmm, this looks the same. Well that's because `alpine` is _also_ a recursive `Makefile` for all of it's subdirectories. Let's drill into a subdirectory at the bottom of the tree to see what it looks like for building an explicit version of an `alpine` image.

```bash
$ make alpine/3.7
all                            Build and deploy image created from Dockerfile.
build                          Build image from Dockerfile.
clean                          Clean state generated by previous images built from Dockerfile.
deploy                         Deploy image built from Dockerfile.
test                           Test and validate files necessary to build image.
help                           Print Makefile usage.
```

That's just the default target, `help`. Let's specify one by invoking the `build` target for this `alpine/3.7` image.

```bash
$ make alpine/3.7-build
[TRACE] - [dockerfiles] - Running 'build' for child image 'alpine/3.7'
[TRACE] - [alpine3.7] - Running 'build'
Sending build context to Docker daemon  9.216kB
...
...
Successfully built 57642cb07bbe
Successfully tagged ahawker/alpine:6cdaa04-1531262409-2704231498
Successfully tagged ahawker/alpine:latest
[TRACE] - [alpine3.7] - Completed 'build'
[TRACE] - [dockerfiles] - Completed 'build' for child image 'alpine/3.7'
```

Based on how the `make help` usage output is created, the recursive targets automatically created from subdirectories will _not_ appear. However, they all follow the same simple pattern of `<directory-path>-<makefile-target-name>`. Let's walk through a few examples:

* `make alpine/3.7-build` - Build the `alpine3.7` image.
* `make alpine/3.7-deploy` - Deploy the `alpine3.7` image.
* `make python/3/3.6.4-clean` - Clean artifacts for the `python3.6.4` image.

As you can see, the `python` example includes subdirectories at depth+1 beyond that of the `alpine` images. The pattern will hold for invoking targets of subdirectories to _any_ depth.

However let's say you don't want to build just `alpine3.7` but all `alpine` images within the repository. You can simply invoke the same targets on the parent directory and it will recursively invoke them for all subdirectories. For example:

* `make alpine-build` - Recursively builds all available `alpine` images.
* `make python/2-build` - Recursively builds all avialable `python2` images.
* `make python-build` - Recursively builds all available `python2` and `python3` images.

That's about it in terms of "usage". The directory structure in conjunction with the `Makefile` define the targets that can be run against the directories.

If you're looking to add new images to this repository, check out the `Contributing` section below.

## Troubleshooting

This repository uses `make` as the build system. If you're not familiar with it, debugging what's happening behind the scenes can sometimes feel like dark magic. Without opening a large can of worms, let's walk through some of the common issues one might encounter while developing within this repository.

### A build command failed with: "manifest for XYZ not found"

**Example:**

```bash
$ make ruby/2.4-build
[TRACE] - [dockerfiles] - Running 'build' for child image 'ruby/2.4'
[TRACE] - [ruby2.4] - Running 'build' for base image 'alpine'
[TRACE] - [ruby2.4] - Completed 'build' for base image 'alpine'
[TRACE] - [ruby2.4] - Running 'build'
Sending build context to Docker daemon  11.78kB
Step 1/21 : ARG REPO
Step 2/21 : ARG BASE_IMAGE
Step 3/21 : ARG TAG=latest
Step 4/21 : FROM $REPO/$BASE_IMAGE:$TAG
manifest for ahawker/alpine:6cdaa04-1531262592-835582456 not found
make[1]: *** [build] Error 1
make: *** [ruby/2.4-build] Error 2
```

**Context:**

When any `make` command is invoked, a number of runtime defined parameters are loaded by the root `Makefile` from it's local `.env`. The two major ones to consider are `BUILD_ID` and `BUILD_TS`. If not specified by the build environment, these will be set to a random identifier and the current timestamp epoch respectively. These values, along with `git` metadata, will be used to `tag` every image build in the current process execution.

**Issue:**

This happens when you build a base image e.g. `alpine3.7` in one process execution and then attempt to build a image that depends on `alpine3.7` in a new process execution.

**Solution:**

Run a `clean` command against the image you're currently trying to build e.g. `make terraform/0.11.7-clean`. If you're trying to rebuild _all_ images, run `make clean`.

### A command failed with: "Required variable XYZ not set"

**Example:**

```bash
$ make build
[TRACE] - [ruby] - Running 'build' for child image '2.4'
Required variable "REPO" not set
make[1]: *** [requires-REPO] Error 1
make: *** [2.4-build] Error 2
```

**Context:**

Each `Makefile` performs validation on the build context to make sure all necessary values are set (or loaded from `.env` files) into the `make` context before executing the corresponding `docker [build|deploy]` command.

**Issue:**

One of the variables defined in a `requires-XYZ` target dependency is not set/empty.

**Solution:**

A few possibilities:

* You've defined a `requires-XYZ` in your `Makefile` but it is not yet defined in your `.env` file. Define it!
* You're running the `Makefile` directly in a subdirectory. This is not currently supported and all images can/should be possible to build from the root `Makefile`.

## Technical Details

This section describes some of the more technical details that may be helpful to the curious minds out there or those contributing/debugging.

### Makefiles

While you may see many `Makefile` within this repository, they're all symlinks back to two files: `Base.make` and `Recursive.make`.

* `Base.make` - Defines how to build a docker image from a set of `.env` files & `Dockerfile`.
* `Recursive.make` - Defines how to recursively call known `make` targets on subdirectories.

An example of the symlinking nature can be seen by examining the hierarchy for the `alpine` image.

```bash
⇒  tree -a alpine .common
alpine
├── .common
│   ├── .env
│   ├── Dockerfile
│   └── Makefile -> ../../.common/Base.make
├── 3.3
│   ├── .env
│   ├── Dockerfile -> ../.common/Dockerfile
│   └── Makefile -> ../.common/Makefile
├── 3.7
│   ├── .env
│   ├── Dockerfile -> ../.common/Dockerfile
│   └── Makefile -> ../.common/Makefile
├── 3.8
│   ├── .env
│   ├── Dockerfile -> ../.common/Dockerfile
│   └── Makefile -> ../.common/Makefile
└── Makefile -> ../.common/Recursive.make
.common
├── .env
├── Base.make
├── Recursive.make
```

The version-specific `Makefile` symlinks back to the `.common` copy which is a symlink to the root directory `.common/Base.make` while the `Makefile` in the `alpine` directory is a symlink to the root directory `.common/Recursive.make`.

### .env

Optional `.env` file(s) can be placed in stratgic locations within the directory structure to define values that are passed to the `Makefile` and potentially `Dockerfile`. The structure of a `.env` file is just a `Makefile` partial and commonly appears as:

```make
# Name of the image created from the Dockerfile.
IMAGE = foobar-1.2.3

# Name of the base image to build on.
BASE_IMAGE = foobar-base

# Version of some package.
PACKAGE_VERSION = 1.2.3
```

There are four types of `.env` files: `root`, `parent`, `local`, and `custom`.

* `root` - Located in the repository root at `.common/.env`.
* `parent` - Located within a `.common/.env` directory that is a sibling to a `Recursive.make` symlink.
* `local` - Located within the same directory as a `Dockerfile` and `Base.make` symlink.
* `custom` - Not supported (yet).

The values of variables within `.env` files can be overwritten by other `.env` files based on the resolution order, which is `root`, `parent`, `local`, and `custom`. This means that more generic variables defined within the `parent` directory can be overwritten by image/version specific values within their `local` copy.

#### Known/Required Variables

Within `.env` files, there's some known/required variables that should be defined. These are classified into three categories: `meta`, `build`, and `custom`.

##### Meta

The `meta` variables are those that are used by the `dockerfiles` repo code itself. Some examples of this are:

* `BUILD_ID` - Identifier (random or CI environment specified) for the build.
* `BUILD_TS` - Unix epoch of when the build process started.
* `TAG` - Identifier string containing multiple pieces of metadata that is applied as a tag to every image created.
* `ARGS` - List of `build` arguments to pass to `docker build` as `--build-arg` values.
* `LABELS` - List of `build` arguments to pass to `docker build` as `--label` values.
* `TAGS` - List of `build` arguments to pass to `docker build` as `--tags` values.

For a comprehensive list of `meta` variables, see the [Variables](docs/variables) page.

##### Build

The `build` variables are those that configure the `build` and `deploy` environment of the images themselves. These are commonly seen as `ARG` entries in the `Dockerfile` themselves. Some examples of these are:

```make
# Version of system 'gem' to install.
GEMS_VERSION = 2.7.7

# Version of the 'bundler' gem to install.
BUNDLER_VERSION = 1.16.2
```

These values should also be added to the `ARGS` `meta` variable if they need to be exposed to the `docker build` process.

##### Custom

The `custom` variables are not yet supported.

### Validation

`Base.make` is responsible for validation of build arguments before invoking the `build` and `deploy` targets which call `docker build` and `docker push` respectively. The logic has been generalized so `.env` must just specify some variables that contain a list of variable names if they need to be validated prior to execution. This commonly appears as:

```make
# List of additional variable names that are required by the 'build' target.
BUILD_REQUIREMENTS_VARIABLES = RUBY_VERSION \
	RUBY_GEM_VERSION \
	GEMS_VERSION \
	BUNDLER_VERSION \
	ALPINE_RUBY_PACKAGE_NAME \
	ALPINE_RUBY_PACKAGE_VERSION \
	ALPINE_RUBY_JSON_PACKAGE_NAME \
	ALPINE_RUBY_IRB_PACKAGE_NAME

# List of additional variable names that are required by the 'clean' target.
CLEAN_REQUIREMENTS_VARIABLES =

# List of additional variable names that are required by the 'deploy' target.
DEPLOY_REQUIREMENTS_VARIABLES = RUBY_VERSION

# List of additional variable names that are required by the 'test' target.
TEST_REQUIREMENTS_VARIABLES =
```

If new variables come into existence that need to be validated for **all** images within the repository, these should be added to the root `.common/.env` file using the `GLOBAL_` prefix variables.

### Dependency Detection

The `Recursive.make` file will automatically detect dependencies and add them as prerequisites for the `build` target.

* If your image specifies a `BASE_IMAGE` that is one built by this repository, the `$(BASE_IMAGE)-build` prerequisite is added.
* All children/sibling files of the `Recursive.make` symlink that aren't empty target files are added as prequisites.

### Out-of-date Targets

The `Recursive.make` file will use [Empty Targets](https://www.gnu.org/software/make/manual/html_node/Empty-Targets.html) to track the execution times of the `build`, `deploy`, and `test` targets. With these empty targets, it can then determine if/when targets should be re-run based on changes to the target prerequsities.

## Contributing

Read this section carefully if you're looking to contribute to this repository.

### New Version to Existing Image

If you're contributing a new version to an existing image, here's a rough checklist of things you should be looking at. For this example, let's say the image is `alpine` and we're adding version `4.2`.

* Create the `4.2` directory under the `alpine` directory. `mkdir -p alpine/4.2`
* Create `Makefile` symlink within the `4.2` directory. `ln -s alpine/.common/Makefile alpine/4.2/Makefile`
* Create `Dockerfile` symlink within the `4.2` directory. `ln -s alpine/.common/Dockerfile alpine/4.2/Dockerfile`
* Create `.env` within the `4.2` directory and specify version-specific variables.

### New Image

If you're adding a new image type to the repository, I first suggest that you examine an existing image, e.g. `alpine` to get a better understanding of the directory/file structure. Once you've done that, continue on with the notes below about the build process.

### Dockerfile

This is just a standard [Dockerfile](https://docs.docker.com/engine/reference/builder/). At a minimum, this should be parameterized with `ARG` instructions for specifying the base image repository, image name and tag. This commonly appears as:

```docker
ARG REPO
ARG BASE_IMAGE
ARG TAG=latest

FROM $REPO/$BASE_IMAGE:$TAG
```

This allows the `Dockerfile` to build off the most recent version of the `BASE_IMAGE` that was created as part of the current build process. If this does not happen or works incorrect, the image will not be properly linked to the others of the same build.

#### Best Practices

It is highly recommended to use `ARG` instructions to parameterize as much of the `Dockerfile` as possible. These values can be injected during the `docker build` process and can be defined in a set of `.env` files. This allows for potential reuse of the `Dockerfile` combination with any number of `.env` files.

### Directory Structure

It is highly recommend that you follow the existing patterns of this repository and just use symlinks of the `Recurisve.make` and `Base.make` files found in the root `.common` directory instead of trying to create your own. For example, let's take a look at how the `alpine` directory is structured:

```bash
$ tree -a alpine
alpine
├── .common
│   ├── .env
│   ├── Dockerfile
│   └── Makefile -> ../../.common/Base.make
├── 3.3
│   ├── .env
│   ├── Dockerfile -> ../.common/Dockerfile
│   └── Makefile -> ../.common/Makefile
├── 3.7
│   ├── .env
│   ├── Dockerfile -> ../.common/Dockerfile
│   └── Makefile -> ../.common/Makefile
├── 3.8
│   ├── .env
│   ├── Dockerfile -> ../.common/Dockerfile
│   └── Makefile -> ../.common/Makefile
└── Makefile -> ../.common/Recursive.make
```

The `alpine` directory contains it's own `.common` directory, a number of version-specific directories and a `Makefile`. The key items to note are:

* The `Makefile` is a relative path symlink to the `.common/Recursive.make` file in the root of the repository.
* The `.common/Makefile` is a relative path symlink to the `.common/Base.make` file in the root of the repository.
* The `Makefile` and `Dockerfile` within each version-specific directory are relative path symlinks into the local `.common` directory.
* The `.env` files are all real and not symlinks.

#### .common

Within the `.common` directory we have three files:

* `Makefile` is just a symlink to `Base.make` that provides targets for building.
* `Dockerfile` is a standard `Dockerfile` that is parameterized with `ARG` and covered in the README section above.
* `.env` is a Makefile partial file that gets automaticalled loaded by the `Makefile`.

#### Version-Specific Directories

Within the version-specific directories, we have the same three files as `.common`. The `Dockerfile` and `Makefile` are just symlinks into `.common`. The `.env` file contains variables used by the `ARG` parameterized `Dockerfile` that are specific to this version of the image.

This is just a standard `Makefile` for GNU Make. At a minimum, it needs to define the following targets:

* `all` - Invokes the `build` and then subsequent `deploy` target.
* `build` - Builds a image by injecting build arguments into `docker build` for the local `Dockerfile`.
* `clean` - Cleans up any state created by previous builds, including images stored by the `Docker` daemon.
* `deploy` - Pushes tagged versions of the locally built image to a remote repository.
* `test` - Runs a test/lint process against files required to build the image.

## Customizing

If you wish to customize the dockerfiles repository to your own liking, I recommend forking the repository and optionally submitting pull-requests upstream to me if it's a fix or helpful addition I might enjoy.

```bash
$ git remote add upstream git@github.com:ahawker/dockerfiles.git
$ git fetch upstream
$ git rebase upstream/master
$ git push origin master
```

## License

[Apache 2.0](LICENSE)
