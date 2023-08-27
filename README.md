# S6 v3 Examples

This directory contains examples of how to use the S6 v3 library.

## Usage

The directory structure is a basic setup. In each of the `up` files, call the actual script, which for simplicity's sake should be in the `scripts` directory.

## Notes

* `dependencies.d` is a directory that contains the dependencies for the service. Should be `base` if there is no dependency, or a file with the name of the service. Multiple services can be specified and should be their own file.
* `down` is omitted for `longrun`, but it can be included if there is a need to do something when the service is stopped.
* `longrun` should be used for any service that we previously had in a `services.d`
* `oneshot` should be used for any service that we previously had in a `cont-init.d`
* If you add a new service, you need to start it up by including a file with the name of the service in the `user/contents.d` directory.
