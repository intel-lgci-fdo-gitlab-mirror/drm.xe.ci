# Xe CI

CI configuration for Xe-related repositories.


## CI Hooks

(Or, Don't Break CI But Still Find Some Issues Challenge)

Hooks let you run arbitrary scripts to run extra checks within the CI pipeline.

- Hooks run only on the public Xe kernel premerge pipeline.
- They are scripts being run in alphabetical order from the `hooks` directory.
- Each script must return success (0) for the hooks stage to succeed - if any single script fails, the entire pipeline fails and hardware testing does not start.
- Hooks run after the kernel is built, software-only tests are done and the actual hardware testing is about to begin. (**Note:** This may change at a later date.)
- The runner image is currently not public (soon!), but for now:
  - Image is an Ubuntu 20.04 container defined in the internal `drivers.gpu.i915.ci.pipelines` repo.
  - You can peek at the current configuration in `docker/Dockerfile.ubuntu2004`.
  - The `docker/common` directory is available in the container as `/common` and often used in most CI stages.
  - The pipeline itself is defined in `pipelines/xe_kernel_pw/Jenkinsfile` - you can trace what's being done to the workspace before `stage('Hooks')` is invoked.
- Working directory for your hooks is the CI workspace root, which looks like this:
  - The `ci` directory contains a `--depth=1` clone of this repo.
  - The `kernel` directory contains a `--depth=1` clone of [the kernel repo](https://gitlab.freedesktop.org/drm/xe/kernel) with the premerge changes applied to the tree with `git am`.
  - The applied patch itself is in the workspace root as `kernel.mbox`.
  - The workspace directory does not have a well-known name and can contain spaces or other special characters. (Quote all paths in your scripts!)
- Adding a new hook: Create a new `XX-name` script (two digits, then `[a-z-_]+` only, no extension - this name format is required for `run-parts` to work) and make it executable. Examples: `00-checkpatch`, `20-clangformat`.
- Disabling a hook: Append a `.disabled` extension to any script.
- Testing: Configure a fresh workspace as described above, then from the workspace root run:
  - `./ci/hooks/99-yourhook` for a single script, or...
  - `./ci/run-hooks.sh` for all of them. (You need `run-parts` or `debianutils` installed for this to work.)
- **Don't go online unless you have to.** Ideally, all checks should run 100% offline. Ask the CI team for a second opinion before doing anything network-related. (If you need to poke Coverity or other external services, you will probably need some setup there anyways.) If you do end up using the network...
- **Don't store any credentials anywhere in the repo.** All secrets and credentials should be provided by the pipeline executor (Jenkins, GitLab CI) - ask the CI team for help with setting it up (usually by setting an environment variable that your script can read, which is then redacted from logs by Jenkins/GitLab).
- **Don't modify the runner state.** This means no installing packages, messing with `systemctl`, et cetera. Instead, add a comment to your script that lists required magic sauce, then ask the CI team to configure the runner image as needed. This is so that when your scripts start, they've got everything ready - hooks are usually executed in a container where all environment changes are lost when `run-hooks.sh` exits.
- Officially, the CI team doesn't support any of this - if you break it, you get to keep all the pieces. Good luck!

Some environment variables are available to let you write scripts portable between CI and your local devenv:

- **Warning:** These names are not yet set in stone and may change within a few months.
- `CI` - always `true` when running under CI.
- `CI_WORKSPACE_DIR` - the main workspace dir in which your hooks execute. It contains all the run-specific stuff.
- `CI_TOOLS_SRC_DIR` - dir which contains this repo (drm/xe/ci).
- `CI_KERNEL_SRC_DIR` - dir which contains the cloned kernel.
- `CI_KERNEL_BUILD_DIR` - dir which contains the main kernel build directory.

The `00-showenv` hook displays current values for these variables on each run for your convenience.

## Kernel (config)

The `kernel` directory contains the configuration used by CI to build drm-tip
to test the i915/xe modules. It's maintained in a way to make it easy for
developers to simply use the final config and at the same time allow updates to
the config without losing track of what options are needed and why.

**For developers and CI to build a kernel**: simply copy the `kernel/kconfig`
file and use it as the configuration. That file is regularly updated with
a base distribution kconfig + CI changes from the `fragments` directory.

**For updating the config**: a few steps are needed to update the configuration
and for that it's important to understand how it's generated:

#. The configuration is derived from a "distro configuration",
   saved in the `kernel/base` directory. Add new distro base
   configs here, then update flavors to make use of them.
#. `kernel/fragments/*.fragment` are config fragments to be
   applied to enable/disable the necessary options.
#. `kernel/flavors/*.flavor` are lists of base + fragment kconfigs
   to apply on top of each other to generate a given kconfig variant.

The script `re-config.sh` is used to automate the process of config updates.
Run `KERNEL_REPO=~/path/to/your/linux/checkout ./re-config.sh debug` to make
the primary `kernel/kconfig` and `kernel/debug.kconfig` files (same contents).
Use any other flavor to create just the `kernel/$FLAVOR.kconfig` file.
When proposing changes, always re-generate all the flavor kconfig's. This can
be done with:

```
KERNEL_REPO=~/path/to/your/linux/checkout ./re-config.sh kernel/flavors/*
```

The `KERNEL_REPO` is required for the `merge_config.sh` script. The default
is to use a checkout in `~/linux`.

Hint: If you are currently booted on a kernel from which you want to pull a new
base kconfig, use `zcat /proc/config.gz > kernel/base/kconfig-name-version`.
