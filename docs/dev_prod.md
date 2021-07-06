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

## Re-enable Password-based Login

During development we may face the situation to access the dev system with user / password instead of ssh key-based auth. The following naive script will re-enable password auth.

```bash
cat /etc/ssh/sshd_config | grep -v ChallengeResponseAuthentication | grep -v PasswordAuthentication | grep -v UsePAM > /tmp/sshd_config && cp /tmp/sshd_config /etc/ssh/sshd_config && systemctl restart sshd
```

**IMPORTANT:** Re-run the autosetup, see [autosetup_rerun.md](autosetup_rerun.md), to enable ssh key-based auth as the default behavior.