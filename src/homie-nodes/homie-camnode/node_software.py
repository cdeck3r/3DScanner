import logging
import os
import re
import subprocess

from homie.node.node_base import Node_Base
from homie.node.property.property_string import Property_String

# search these directories for a .git subdir
repo_dirs = ['/boot/autosetup/3DScanner', '/3DScannerRepo']

logger = logging.getLogger(__name__)


class Node_Software(Node_Base):
    """A camnode's software revision

    scanner/camnode-hwaddr/software/repo-revision
    scanner/camnode-hwaddr/software/local-revision
    """

    def __init__(
        self,
        device,
        id="software",
        name="Software",
        type_="software",
        retain=True,
        qos=1,
    ):

        super().__init__(device, id, name, type_, retain, qos)
        # scanner/camnode-hwaddr/software/repo-revision
        sw_repo = self.sw_repo_revision()
        logger.info('Repo software revision: {}'.format(sw_repo))
        self.repo_revision = Property_String(
            node=self, id='repo-revision', name='Repository Revision', value=sw_repo
        )

        # scanner/camnode-hwaddr/software/local-revision
        sw_local = self.sw_local_revision()
        logger.info('Local software revision: {}'.format(sw_local))
        self.local_revision = Property_String(
            node=self, id='local-revision', name='Local Revision', value=sw_local
        )
        self.add_property(self.repo_revision)
        self.add_property(self.local_revision)

    def __str__(self):
        return str(self.__class__.__name__)

    def _repo_dir(self):
        for d in repo_dirs:
            if os.path.exists(os.path.join(d, '.git')):
                return d
        return None

    def _git_fetch(self, repo_dir, branch='master'):
        """Update the remote master, but do not merge"""
        # git fetch origin master

        # src: https://janakiev.com/blog/python-shell-commands/
        process = subprocess.run(
            ['sudo', 'git', 'fetch', 'origin', branch],
            cwd=repo_dir,
            check=True,
            capture_output=True,
            universal_newlines=True,
        )
        # execute process
        process

    def sw_repo_revision(self):
        """Read the repo's revision"""
        rd = self._repo_dir()
        try:
            if rd is not None:
                self._git_fetch(repo_dir=rd, branch='master')
                with open(
                    os.path.abspath(os.path.join(rd, '.git/FETCH_HEAD')), 'r'
                ) as revfile:
                    firstline = revfile.readline().rstrip()
                    rev = re.search('([a-z0-9]+)', firstline)
                    revision = rev.group(0)
        except Exception:
            revision = 'unknown'
        return revision

    def sw_local_revision(self):
        """Read the local's revision"""
        rd = self._repo_dir()
        if rd is not None:
            with open(
                os.path.abspath(os.path.join(rd, '.git/refs/heads/master')), 'r'
            ) as revfile:
                revision = revfile.readline().rstrip()
        else:
            revision = 'unknown'
        return revision
