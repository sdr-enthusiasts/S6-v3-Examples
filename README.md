# S6 v3 Examples

This directory contains examples of how to use the S6 v3 library.

## Usage

The directory structure is a basic setup. In each of the `up` files, call the actual script, which for simplicity's sake should be in the `scripts` directory.

## Notes

* `dependencies.d` is a directory that contains the dependencies for the service. It appears to not be required for `oneshot`, and not sure if you could add it to stack cont-init deps. It is required for `longrun`. Should be `base` if there is no dependency, or a file with the name of the service. Multiple services can be specified and should be their own file.
* `down` is omitted for `longrun`, but it can be included if there is a need to do something when the service is stopped.
* `longrun` should be used for any service that we previously had in a `services.d`
* `oneshot` should be used for any service that we previously had in a `cont-init.d`
* If you add a new service, you need to start it up by including a file with the name of the service in the `user/contents.d` directory.
* `cont-finish.d` is NOT migrated. See below for more.

## How to migrate

If you clone this repo you can use the `migrate.sh` script to migrate. Pass it the directory of the rootfs. It will go through all `cont-init.d` and `services.d` directories and create the appropriate `up` and `down` files. All `services.d` files will be created as `longrun` and will have dependencies on all of the files in `cont-init.d`. All `cont-init.d` files will be created as `oneshot` and will have no dependencies.

Shebang lines will be corrected in the scripts.

You will need to go through and potentially add additional dependencies to the `dependencies.d` files in the longrun services.

All of the old files will be moved to the rootfs directory under a folder called `back`. You can then go through and delete the files that you don't need anymore.

### Healthcheck notes

If the HC file checks the `/run/s6/legacy-services` the path is patched to `/run/services`. If you specifically use Mike's `check_pid` stuff you may have to change the path instead look at `/etc/s6-overlay/scripts` for it to work. Additionally, if the HC script checks for abnormal deaths you will need to remove references to `/run` and change the find line to look something like

```bash
mapfile -t SERVICES < <(find /run/service -maxdepth 1 -not -name "*s6*" | tail +2)
```

I've chosen to not attempt to automate this in the migration script because each HC script is fairly bespoke and it would be difficult to account for all of the different ways that it could be written.

### cont-finish.d notes

cont-finish.d requires a bit of thought in how to migrate, so it'll be a manual process. Likely, we have tied a cont-finish.d process to a cont-init.d process, so the appropriate best course of action will be to move the cont-finish.d script to the `/etc/s6-overlay/scripts/` directory and add it to the `down` file of the one-shot that it should be paired with. If it is a cont-init.d process that does not have a cont-init script that it is paired with, create a new oneshot service, with an empty up file and call the script in the down file.

If the cont-finish.d script is needed for a longrun service, then it should be added to the `finish` file of the longrun service. This finish file is called *EVERY* time the service is stopped, so it should be used with caution. Likely, you will want to add exit code checks to the script to make sure that it only runs when it should.

To summarize, if the service is a oneshot the down script is called only when the container is stopped. If the service is a longrun the finish script is called every time the service is stopped, which may or may not be a container down.

See [this](https://github.com/just-containers/s6-overlay#executing-initialization-and-finalization-tasks) for more info.

## Resources

* [Tutorial](https://darkghosthunter.medium.com/how-to-understand-s6-overlay-v3-95c81c04f075)
* [S6 Github](https://github.com/just-containers/s6-overlay)
* [S6 Github v2 to v3 Migration Guide](https://github.com/just-containers/s6-overlay/blob/master/MOVING-TO-V3.md)
