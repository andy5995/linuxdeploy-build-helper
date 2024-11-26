# linuxdeploy Build Helper Container

A docker container that aims to help build an
[AppImage](https://github.com/AppImage/AppImageKit) on multiple architectures
using [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy).

Latest version: v2-focal

v2-jammy is also available if for some reason you require a more recent
version Ubuntu.

## Available architectures

    amd64
    arm64
    arm/v7

(The appimage plugin doesn't yet support 'ppc64le' or 's390x')

## Usage

Make a `docker` sub-directory within your project and copy `.env` and
`docker-compose.yml` to it. Add custom variables to suit your needs. Add your
numeric user and group id to the corresponding variables in `.env`. You can
find them by using:

    id -u
    id -g

To build the AppImage:

    docker-compose -f docker/docker-compose.yml run --rm build

This is meant to be run from the source root of your project. Using the
command above, your current directory will be mounted in the container at
`/workspace`.

You can see an example of an AppImage build script at
[rmw/packaging/appimage/pre-appimage.sh](https://github.com/theimpossibleastronaut/rmw/blob/master/packaging/appimage/pre-appimage.sh).
Add the `/path/to/script` in your custom `.env` file.

When the container starts, 'root' changes the UID of user 'builder' (a user
created during the build of the Dockerfile) to HOSTUID. This allows builder to
build your project and create the AppImage without root privileges (the
resulting files will be owned by you).

You may use `sudo` in your script to install packages or do other things.

If you would like to look around the container, you can use

    docker run -it --rm --entrypoint bash andy5995/linuxdeploy:v2-focal

## Locally

To build for other architectures, you may need to use qemu with docker. There
may be other ways, but you can check out [this
document](https://www.stereolabs.com/docs/docker/building-arm-container-on-x86)
for starters. If you are set up to build on other architectures, edit the
**PLATFORM** variable in docker-compose.yml, or export it when running
`docker-compose`:

    PLATFORM=linux/arm64 docker-compose ...

## In a GitHub Runner

See [tests.yml](https://github.com/andy5995/linuxdeploy-build-helper-container/blob/trunk/.github/workflows/test.yml)

## linuxdeploy Plugins

These plugins are installed in the container:

* [linuxdeploy-plugin-gtk](https://github.com/linuxdeploy/linuxdeploy-plugin-gtk)
* [linuxdeploy-plugin-qt](https://github.com/linuxdeploy/linuxdeploy-plugin-qt)

## Note

The container runs Ubuntu 20.04 (Focal Fossil). See [this
discussion](https://github.com/orgs/AppImage/discussions/1254) for more
details on why I chose that version of Ubuntu.

Some 'GITHUB_...' variables will not work inside the container.

Recent versions of cmake, meson, and ninja are installed to
'/home/builder/.local/bin' which is the first path in PATH (installing them
with `apt` will probably offer no benefit).

If you want to see more details about the container or what packages are
pre-installed, look at the two Dockerfiles in this repository. If you'd like
more packages pre-installed, please open an issue.

## Contributing

Ok, but it's a good idea to open an issue and ask about a change before
starting work on a pull request. Someone, or myself, may already be working on
it, or planning to. Also, please consult [this
guide](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/best-practices-for-pull-requests)
before you submit a pull request.
