#
# Testinfra testcases to validate the autosetup run.
#
# Author: cdeck3r
#

import pytest

#####################################################
# Tests
#####################################################


@pytest.mark.usefixtures("centralnode_ssh_config")
class TestAutosetupCentralnode:
    @pytest.mark.parametrize('nodetype', ['centralnode'])
    def test_hostname(self, pytestconfig, host, nodetype):
        hostname = pytestconfig.getini(nodetype.lower())
        assert (
            host.run("hostname").stdout.rstrip()
            == hostname[0 : len(nodetype + '-') + 12]
        )

    def test_booter_done(self, host):
        assert host.file('/boot/booter.done').exists

    def test_ssh_avahi_service_file(self, host):
        assert host.file('/etc/avahi/services/ssh.service').exists
        assert host.file('/etc/avahi/services/ssh.service').mode == 0o644

    @pytest.mark.parametrize('nodetype', ['centralnode'])
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

    def test_autosetup_python_installed(self, host):
        pkg = host.package('python3')
        assert pkg.is_installed
        assert pkg.version.startswith('3.7')

    def test_autosetup_pip3_installed(self, host):
        pkg = host.package('python3-pip')
        assert pkg.is_installed

    def test_autosetup_mosquitto_installed(self, host):
        pkg = host.package('mosquitto')
        assert pkg.is_installed

    def test_autosetup_mosquitto_broker(self, host):
        # test centralnode specific config file
        assert host.file('/etc/mosquitto/conf.d/centralnode_mosquitto.conf').exists
        assert (
            host.file('/etc/mosquitto/conf.d/centralnode_mosquitto.conf').mode == 0o644
        )
        assert (
            host.file('/etc/mosquitto/conf.d/centralnode_mosquitto.conf').user == 'root'
        )
        assert (
            host.file('/etc/mosquitto/conf.d/centralnode_mosquitto.conf').group
            == 'root'
        )
        # test service itself
        assert host.service('mosquitto').is_enabled
        assert host.service('mosquitto').is_running

    def test_autosetup_mosquittoclients_installed(self, host):
        pkg = host.package('mosquitto-clients')
        assert pkg.is_installed

    def test_autosetup_nginx(self, host):
        assert host.package('nginx').is_installed
        assert host.service('nginx').is_enabled
        assert host.service('nginx').is_running

    def test_autosetup_homie4_installed(self, host):
        assert (
            host.run('pip3 freeze | grep Homie4').stdout.rstrip().startswith('Homie4')
        )

    def test_autosetup_scanodis_tracker_ini(self, host):
        assert host.file('/boot/autosetup/scanodis_tracker.ini').exists
        assert host.file('/boot/autosetup/scanodis_tracker.ini').user == 'root'
        assert host.file('/boot/autosetup/scanodis_tracker.ini').user == 'root'

    def test_autosetup_scanodis_installed(self, host):
        assert host.file('/home/pi/scanodis/scanodis.sh').exists
        assert host.file('/home/pi/scanodis/scanodis.sh').mode == 0o700

    def test_autosetup_scanodis_cronjob(self, host):
        assert (
            host.run('crontab -l | grep scanodis')
            .stdout.rstrip()
            .startswith('0 * * * * /home/pi/scanodis/scanodis.sh')
        )

    def test_autosetup_avahi_utils_installed(self, host):
        assert host.package('avahi-utils').is_installed

    @pytest.mark.parametrize('nodetype', ['camnode'])
    def test_avahi_find_camnode(self, pytestconfig, host, nodetype):
        camnode_name = pytestconfig.getini(nodetype.lower())
        cmd = "avahi-resolve -n -4 " + camnode_name
        assert host.run(cmd).succeeded

    @pytest.mark.parametrize('nodetype', ['camnode'])
    def test_avahi_browse_camnode(self, pytestconfig, host, nodetype):
        camnode_name = pytestconfig.getini(nodetype.lower())
        cmd = (
            r"avahi-browse -atr | grep hostname | tr '[:space:] ' '\n' | grep local | sort | uniq | sed 's/\[\(.\+\)\]/\1/g'"
            + " | grep "
            + camnode_name
        )
        assert host.run(cmd).succeeded

    def test_avahi_resolve_name_conflict(self, host):
        service_unit_file = 'avahi-resolve-name-conflict.service'
        cmd = (
            'systemctl --no-pager --no-legend list-unit-files | grep -c '
            + service_unit_file
        )
        assert host.run(cmd).succeeded
        assert host.run(cmd).stdout.rstrip() == '1'
