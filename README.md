# Xe CI

CI configuration for Xe-related repositories.


## CI Hooks

(Or, Don't Break CI But Still Find Some Issues Challenge)

Hooks let you run arbitrary scripts to run extra checks within the CI pipeline.

- Hooks run only on the public Xe kernel premerge pipeline.
- They are scripts being run in alphabetical order from the `hooks` directory.
- Each script must return success (0) for the hooks stage to succeed - if any single script fails, the entire pipeline fails and hardware testing does not start.
- Hooks run after the kernel is built, software-only tests are done and the actual hardware testing is about to begin. (**Note:** This may change at a later date.)
- Working directory for your hooks is the CI workspace root, which looks like this:
  - The `ci` directory contains a `--depth=1` clone of this repo.
  - The `kernel` directory contains a `--depth=1` clone of [the kernel repo](https://gitlab.freedesktop.org/drm/xe/kernel) with the premerge changes applied to the tree with `git am`.
  - The applied patch itself is in the workspace root as `kernel.mbox`.
  - The workspace directory does not have a well-known name and can contain spaces or other special characters. (Quote all paths in your scripts!)
- Adding a new hook: Create a new `XXname` script (two digits, then lowercase A-Z only, no extension - this name format is required for `run-parts` to work) and make it executable. Examples: `00checkpatch`, `20clangformat`.
- Disabling a hook: Append a `.disabled` extension to any script.
- Testing: Configure a fresh workspace as described above, then from the workspace root run:
  - `./ci/hooks/99yourhook` for a single script, or...
  - `./ci/run-hooks.sh` for all of them. (You need `run-parts` or `debianutils` installed for this to work.)
- **Don't go online unless you have to.** Ideally, all checks should run 100% offline. Ask the CI team for a second opinion before doing anything network-related. (If you need to poke Coverity or other external services, you will probably need some setup there anyways.) If you do end up using the network...
- **Don't store any credentials anywhere in the repo.** All secrets and credentials should be provided by the pipeline executor (Jenkins, GitLab CI) - ask the CI team for help with setting it up (usually by setting an environment variable that your script can read, which is then redacted from logs by Jenkins/GitLab).
- **Don't modify the runner state.** This means no installing packages, messing with `systemctl`, et cetera. Instead, add a comment to your script that lists required magic sauce, then ask the CI team to configure the runner image as needed. This is so that when your scripts start, they've got everything ready - hooks are usually executed in a container where all environment changes are lost when `run-hooks.sh` exits.
- Officially, the CI team doesn't support any of this - if you break it, you get to keep all the pieces. Good luck!
