# dependency

## Preparing a Development Environment

The recommended workflow for developing on this project involves using [pyenv] to
manage the version of Python you are using along with Python's built-in *venv* module
to isolate the project's dependencies.

### Step 1: Install Python

*dependency* requires Python 3.6.2 or newer. For development purposes, it is
highly recommended that you use [pyenv] to help manage the version of Python
you are using per project.

To install [pyenv] on Mac OS X, the preferred method is to use [Homebrew]:

```sh
brew update
brew install pyenv
```

For other platforms, see the [pyenv] installation instructions.

Once pyenv is installed you can install the version of Python specified in
*.python-version*:

```sh
pyenv install
```

[Homebrew]: https://brew.sh/
[pyenv]: https://github.com/yyuu/pyenv

### Step 2: Create a virtual environment

Creating a project specific virtual environment to isolate the project's
dependencies can be accomplished with the built-in [venv] module.

```sh
python -m venv --prompt dependency venv
```

> *NOTE*: This commands executes the *venv* module (via the `-m` option) to
> create a new virtual environment named "venv". When activated, the virtual
> environment will use the prompt "dependency".

The project's virtual environment can be activated by sourcing the `activate`
script that matches your shell. For example when using bash/zsh, run:

```sh
. venv/bin/activate
```

You will know that you are in an active virtual environment when you see the
prompt (e.g. `(fileservice)` prefix in front of your normal shell prompt.

[venv]: https://docs.python.org/3/tutorial/venv.html


### Step 3: Upgrade Pip

This project uses PEP508 style URLS for project dependencies that are linked
directly to a Git repository, which requires pip v18.2 or newer.

```sh
pip install --upgrade pip
```


### Step 4: Install the project's dependencies

```sh
pip install -r requirements.txt
```

### Step 5: Install Docker

In practice running dependency in an environment, along with all of the other
microservices it depends on, is the best way to test and develop. This is
currently achieved through the use a docker-compose.yml file, which establishes
such an environment and is configured to automatically reload the service code
as it changes, which eliminates the need to manually restart the app.

Follow the instructions for installing [Docker Desktop] for your os:

[Docker Desktop]: https://www.docker.com/products/docker-desktop

Login to the Chimera Developer Network (CDN) Docker registry:

```sh
docker login cdn-docker.363-283.io
```


## Running with Docker

To start up the Docker Environment, utilize Docker Compose.
    
    $ docker-compose up --build

> *NOTE*: The command above runs the app in the background. To tail the logs,
> you can run `docker-compose logs -f` or `docker-compose logs -f dependency`
> (to narrow it down to just the logs for the given service.)

To stop the services:

```sh
docker-compose stop
```

### Test Running Services

Go to `https://localhost/services/dependency/1.0` and a default landing page

> *NOTE* You will need to provide user_dn and ssl_s_dn headers to make a valid request. We normally use a p12 certificate for this.


## Build an RPM

```sh
CI_PROJECT_DIR=`pwd` CI_PIPELINE_ID=12345678 scripts/build_rpm.sh
```


### Test the RPM

To test the RPM installation, you need to install it on a RHEL/CentOS
system. The following instructions are enough to test that the RPM installs, but
stops there, since the rest of ecosystem is not configured.


Create a CentOS 6 Container w/the dist mounted to */rpms*:

```sh
docker run --rm -it -v `pwd`/dist:/rpms centos:6 /bin/bash
```

Enable the IUS Yum repository:

```sh
yum install -y \
    https://repo.ius.io/ius-release-el6.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm


Install the dependency RPM:

> *NOTE*: the filename will be different on your system.

```sh
yum localinstall -y /rpms/dependency-1.0-1.201910170201.x86_64.rpm
```

Check that the processes started

```sh
ps -ef | grep gunicorn  # ...two instances of gunicorn
```