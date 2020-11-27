#
# Testinfra testcases for systemd service announcing homie devices
#
# Author: cdeck3r
#

import pytest


@pytest.mark.usefixtures("camnode_ssh_config")
class TestHomieServiceCamnode:
    @pytest.mark.parametrize('userhome', ['/home/pi'])
    @pytest.mark.parametrize('servicefile', ['homie_camnode.service'])
    def test_service_file(self, host, userhome, servicefile):
        assert host.file(userhome + '/.config/systemd/user').exists
        assert host.file(userhome + '/.config/systemd/user').is_directory
        assert host.file(userhome + '/.config/systemd/user/' + servicefile).exists
        assert (
            host.file(userhome + '/.config/systemd/user/' + servicefile).mode == 0o644
        )
        assert host.file(userhome + '/.config/systemd/user/' + servicefile).user == 'pi'
        assert (
            host.file(userhome + '/.config/systemd/user/' + servicefile).group == 'pi'
        )

    @pytest.mark.parametrize('servicefile', ['homie_camnode.service'])
    def test_service_state(self, host, servicefile):
        list_unit_files = (
            'systemctl --user --no-pager --no-legend list-unit-files | grep '
            + servicefile
            + ' | wc -l'
        )
        assert host.run(list_unit_files).stdout.rstrip() == '1'
        service_enabled = (
            'systemctl --user --no-pager --no-legend is-enabled ' + servicefile
        )
        # assert host.run(service_enabled).stdout.rstrip() == 'enabled'
        service_state = (
            'systemctl --user --no-pager --no-legend is-active ' + servicefile
        )
        assert host.run(service_state).stdout.rstrip() == 'active'
