# Development and Production

We separate development activities from the software running on the on-site system by the use of two branches in the repository.

* dev - the developer implements new functionality in this branch at first
* master - this branch is installed on the devices in the on-site production installation

The [autosetup](autosetup_rerun.md) selects the branch found in the first line of the file `/boot/BRANCH`.

## Development Steps

1. Checkout `dev` branch
1. Develop new functionality
1. Test functionality
1. Commit and push in `dev` branch

## Pull Development into Production

Create a pull request from the `dev` branch into the `master` branch. Finally, [re-run autosetup](autosetup_rerun.md) to reboot the node and install the new software from the repository's master branch.
