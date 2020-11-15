""" doit task creator 

doit is a build tool to execute any kind of task
https://pydoit.org/

Objective: Automate various linter tasks

"""

import glob
import os

import doit
from doit.action import CmdAction

DOIT_CONFIG = {
    'default_tasks': ['default'],  # all by default
    'verbosity': 1,
}


def initial_dir():
    return doit.get_initial_workdir()


def files_in_dir(dirpath, pattern='*', recursive=False):
    path_search_pattern = os.path.join(os.path.abspath(dirpath), pattern)
    matched_paths = glob.glob(path_search_pattern, recursive=recursive)
    matched_files = [f for f in matched_paths if os.path.isfile(f)]

    return matched_files


def task_default():
    """Inform user to specify a concrete task"""

    return {
        'actions': [
            ['echo', 'Specify a concrete task. Run `doit list` for a task list.']
        ],
        'verbosity': 2,
    }


def task_shellcheck():
    """Run shellcheck linter on bash scripts"""

    pattern = '**/*.sh'
    iwd = initial_dir()
    file_dep = files_in_dir(iwd, pattern=pattern, recursive=True)

    def shellcheck():
        files = " ".join(file_dep)
        return "shellcheck -Calways " + files

    return {'actions': [CmdAction(shellcheck)], 'file_dep': file_dep}


def task_shfmtdiff():
    """Run shfmt on bash scripts and output formatting diffs (don't change files)"""

    pattern = '**/*.sh'
    iwd = initial_dir()
    file_dep = files_in_dir(iwd, pattern=pattern, recursive=True)

    def shfmtdiff():
        files = " ".join(file_dep)
        return "shfmt -ln bash -i 4 -d " + files

    return {'actions': [CmdAction(shfmtdiff)], 'file_dep': file_dep}


def task_shfmt():
    """Run shfmt formatter on bash scripts. It changes files!!!"""

    pattern = '**/*.sh'
    iwd = initial_dir()
    file_dep = files_in_dir(iwd, pattern=pattern, recursive=True)

    def shfmt():
        files = " ".join(file_dep)
        return "shfmt -ln bash -i 4 -w " + files

    return {'actions': [CmdAction(shfmt)], 'file_dep': file_dep}


def task_blackdiff():
    """Run python's black and output diffs (don't change files)"""

    pattern = '**/*.py'
    iwd = initial_dir()
    file_dep = files_in_dir(iwd, pattern=pattern, recursive=True)

    def blackdiff():
        files = " ".join(file_dep)
        return "black -S --check --diff --color " + files

    return {'actions': [CmdAction(blackdiff)], 'file_dep': file_dep}


def task_black():
    """Run python's black code formatter. It changes files!!!"""

    pattern = '**/*.py'
    iwd = initial_dir()
    file_dep = files_in_dir(iwd, pattern=pattern, recursive=True)

    def black():
        files = " ".join(file_dep)
        return "black -S --color " + files

    return {'actions': [CmdAction(black)], 'file_dep': file_dep}


def task_isortdiff():
    """Run python's isort and output diffs (don't change files)"""

    pattern = '**/*.py'
    iwd = initial_dir()
    file_dep = files_in_dir(iwd, pattern=pattern, recursive=True)

    def isortdiff():
        files = " ".join(file_dep)
        return "isort --check --diff " + files

    return {'actions': [CmdAction(isortdiff)], 'file_dep': file_dep}


def task_isort():
    """Run python's isort formatter. It changes files!!!"""

    pattern = '**/*.py'
    iwd = initial_dir()
    file_dep = files_in_dir(iwd, pattern=pattern, recursive=True)

    def isort():
        files = " ".join(file_dep)
        return "isort " + files

    return {'actions': [CmdAction(isort)], 'file_dep': file_dep}
