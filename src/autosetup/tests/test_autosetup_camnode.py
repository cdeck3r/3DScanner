#
# Testinfra testcases to validate the autosetup run.
#
# Author: cdeck3r
#

import pytest

#####################################################
# Tests
#####################################################


@pytest.mark.usefixtures("camnode_ssh_config")
class TestAutosetupCamnode:
    @pytest.mark.parametrize('nodetype', ['camnode'])
    def test_hostname(self, pytestconfig, host, nodetype):
        hostname = pytestconfig.getini(nodetype.lower())
        assert host.run("hostname").stdout.rstrip() == hostname

    def test_booter_done(self, host):
        assert host.file('/boot/booter.done').exists

    def test_ssh_avahi_service(self, host):
        assert host.file('/etc/avahi/services/ssh.service').exists
        assert host.file('/etc/avahi/services/ssh.service').mode == 0o644

    @pytest.mark.parametrize('nodetype', ['camnode'])
    def test_autosetup_nodetype(self, host, nodetype):
        assert host.file('/boot/autosetup/NODETYPE').exists
        assert host.file('/boot/autosetup/NODETYPE').contains(nodetype.upper())

    def test_autosetup_git_installed(self, host):
        pkg = host.package('git')
        assert pkg.is_installed
        assert pkg.version.startswith('1:2.20')

    def test_autosetup_repo_exists(self, host):
        assert host.file('/boot/autosetup/3DScanner/.git').is_directory

    def test_autosetup_install_scripts_exists(self, host):
        assert host.file('/boot/autosetup/3DScanner/src/raspi-autosetup').is_directory
        assert host.file(
            '/boot/autosetup/3DScanner/src/raspi-autosetup/install_commons.sh'
        ).exists
        assert host.file(
            '/boot/autosetup/3DScanner/src/raspi-autosetup/install_camnode.sh'
        ).exists
        assert host.file(
            '/boot/autosetup/3DScanner/src/raspi-autosetup/install_centralnode.sh'
        ).exists

    def test_repo_branch(self, host):
        """Test the branch the repository's head points to.

        If there is a `/boot/BRANCH` file, the repo head is
        equal the branch from this file. Allowed values are `dev` or `master`.
        Otherwise the repo's head points to the master branch.
        """
        git_head = '/boot/autosetup/3DScanner/.git/HEAD'
        if host.file('/boot/BRANCH').exists:
            branch = host.run('head -1 /boot/BRANCH').stdout.rstrip()
            if branch == 'dev':
                assert (
                    host.run('head -1 ' + git_head).stdout.rstrip()
                    == 'ref: refs/heads/dev'
                )
            elif branch == 'master':
                assert (
                    host.run('head -1 ' + git_head).stdout.rstrip()
                    == 'ref: refs/heads/master'
                )
            else:
                assert False, 'No valid branch: ' + branch
        else:
            assert (
                host.run('head -1 ' + git_head).stdout.rstrip()
                == 'ref: refs/heads/master'
            )

    def test_autosetup_python_installed(self, host):
        pkg = host.package('python3')
        assert pkg.is_installed
        assert pkg.version.startswith('3.7')

    def test_autosetup_pip3_installed(self, host):
        pkg = host.package('python3-pip')
        assert pkg.is_installed

    def test_autosetup_raspistill_installed(self, host):
        exec_file = '/usr/bin/raspistill'
        if host.file(exec_file).is_symlink:
            exec_file = host.file('/usr/bin/raspistill').linked_to
        assert host.file(exec_file).exists
        assert host.file(exec_file).mode == 0o755

    def test_autosetup_mosquittoclients_installed(self, host):
        pkg = host.package('mosquitto-clients')
        assert pkg.is_installed

    def test_autosetup_homie4_installed(self, host):
        assert (
            host.run('pip3 freeze | grep Homie4').stdout.rstrip().startswith('Homie4')
        )

    def test_autosetup_camera(self, host):
        assert host.run('sudo raspi-config nonint get_camera').stdout.rstrip() == '0'

    def test_avahi_resolve_name_conflict_cronjob(self, host):
        jobfile = 'avahi-resolve-name-conflict.sh'

        assert host.run('sudo ls -l /root/' + jobfile).succeeded
        assert (
            host.run('sudo ls /root/' + jobfile).stdout.rstrip() == '/root/' + jobfile
        )

        assert (
            host.run('sudo crontab -l | grep ' + jobfile)
            .stdout.rstrip()
            .startswith('@reboot sleep 60 && /root/' + jobfile)
        )

    def test_autosetup_images_housekeeping(self, host):
        assert host.file('/home/pi/images').is_directory
        assert host.file('/home/pi/housekeeping').is_directory
        assert host.file('/home/pi/housekeeping/housekeeping.sh').exists
        assert (
            host.run('crontab -l | grep housekeeping.sh | grep /home/pi/images')
            .stdout.rstrip()
            .startswith(
                '0 3 * * * /home/pi/housekeeping/housekeeping.sh /home/pi/images'
            )
        )

    def test_autosetup_housekeeping_logrotate(self, host):
        assert host.file('/home/pi/housekeeping/logrotate.conf').exists
        assert host.run(
            'grep "/home/pi/log/housekeeping.log" /home/pi/housekeeping/logrotate.conf'
        ).succeeded
        assert (
            host.run('crontab -l | grep housekeeping | grep logrotate')
            .stdout.rstrip()
            .startswith(
                '30 2 * * * /usr/sbin/logrotate -s /home/pi/log/logrotate_housekeeping.state'
            )
        )

    def test_autosetup_watchdog_active(self, host):
        assert host.run(
            'journalctl --no-pager -k | grep -q "Set hardware watchdog to"'
        ).succeeded

    def test_autosetup_power_services(self, host):
        # we test that power-consuming devices are switched off
        # wifi and bluetooth services are inactive
        assert (
            host.run('systemctl is-active wpa_supplicant')
            .stdout.rstrip()
            .startswith('inactive')
        )
        assert (
            host.run('systemctl is-active bluetooth')
            .stdout.rstrip()
            .startswith('inactive')
        )
        assert (
            host.run('systemctl is-active hciuart')
            .stdout.rstrip()
            .startswith('inactive')
        )

    @pytest.mark.xfail
    def test_autosetup_power_bluetooth_active(self, host):
        # we test that power-consuming devices are switched off
        # bluetooth shall not be active
        assert host.run('sudo rfkill list | grep -iq bluetooth').succeeded

    @pytest.mark.xfail
    def test_autosetup_power_usb_active(self, host):
        # we test that power-consuming devices are switched off
        # USB is off
        assert host.run('sudo lspci | grep -q "USB"').succeeded
