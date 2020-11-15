# Code Quality

[User story](https://trello.com/c/w6xiroo6):
> As a developer, I want to utilize linter tools, so that I can improve code quality. 

[User story](https://trello.com/c/55XXicwf):
> As a developer, I want to start various linters for python and bash files, so that I have immediate feedback on my code quality.

## Tools

The dockerized dev system 3dsdev (see [docker-compose.yml](https://github.com/cdeck3r/3DScanner/blob/master/docker-compose.yml)) provides the following tools to improve the code quality:

* [shellcheck](https://github.com/koalaman/shellcheck)
* [shfmt](https://github.com/mvdan/sh)
* [black](https://github.com/psf/black)
* [isort](https://pycqa.github.io/isort/)

## Usage

The developer can apply the tools to `*.sh` and `*.py` files using the [doit](https://pydoit.org/) build tool. doit defines tasks for each tool in `/3DScanner/scripts/dodo.py`. The dev system defines the following bash alias

```bash
alias doit="doit -f /3DScanner/scripts/dodo.py"
```

As a result, invoking doit in a directory always refers to the `dodo.py` file from the scripts directory.

List all tasks:

```bash
doit list
```

### Linting bash scripts

Change into a directory, which contains `*.sh` bash scripts. The developer may run *shellcheck* and *shfmt* for bash scripts. In each case, doit recursively traverses the directory and all its subdirectories for all `*.sh` files and runs the tools on each file. 

**Run shellcheck**
```bash
doit shellcheck
```
Outputs the analysis results on stdout.

**Run shfmtdiff** 
```bash
doit shfmtdiff
```
Outputs the diff how *shfmt* will change the script.

**Run shfmt** 
```bash
doit shfmt
```
Reformats the shell script. It changes the files.

### Linting python code

Change into a directory, which contains `*.py` python files. The developer may run *isort* and *black*. In each case, doit recursively traverses the directory and all its subdirectories for all `*.py` files and runs the tools on each file. 

**Run isortdiff**
```bash
doit isortdiff
```
Outputs the diff how *isort* will change the files.

**Run isort** 
```bash
doit isort
```
Reformats the imports in the python files. It changes the files.

**Run blackdiff** 
```bash
doit blackdiff
```
Outputs the diff how black will changes the files.

**Run black** 
```bash
doit black
```
Runs the black code formatter. It changes the files.
