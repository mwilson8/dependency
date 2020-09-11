"""
dependency
------------

"""
from datetime import datetime
from glob import glob
from json import dump
from os import getenv, getcwd, makedirs, path
from setuptools import Command, find_packages, setup


class ChangelogPdfCommand(Command):
    description = 'Generate a PDF of the CHANGELOG.'
    user_options = [
        ('input-dir=', 'i', 'input directory'),
        ('output-dir=', 'o', 'output directory')
    ]

    def initialize_options(self):
        """Initialize the command's options."""
        self.input_dir = getcwd()
        self.output_dir = path.join(getcwd(), 'dependency', 'static', 'apidocs')

    def finalize_options(self):
        """Finalize/validate the command's options."""
        if self.input_dir is None:
            raise Exception('No base directory set.')

        if self.output_dir is None:
            raise Exception('Parameter --output-dir is missing')

    def __pandoc_cmd(self, input_mount, *args):
        """Convert a markdown file to PDF.

        :param input_mount: A docker volume mount (e.g. "/some/local/path:/container/path").
        :param args: Additional arguments to pass to the pandoc command.
        :return: A list representing a call to execute a Dockerized version of Pandoc.
        """
        return [
            'docker', 'run', '--rm', '--entrypoint', 'pandoc-md-strip-h1',
            '-v', input_mount,
            '-v', f'{path.abspath(self.output_dir)}:/output',
            'cdn-docker.363-283.io/chimera/pandoc-texlive:1.0.2',
            *args
        ]

    def run(self):
        from subprocess import check_call

        check_call(self.__pandoc_cmd(f"{path.abspath(self.input_dir)}:/docs",
                                     'CHANGELOG.md', '-s', '--pdf-engine=xelatex', '-o', '/output/changelog.pdf'))


class VersionJsonCommand(Command):
    """
    *NOTE*: This command requires git to be installed on the system that it is run.

    You can configure the command via the ``setup.cfg`` file. For example:

        [version]
        output-dir = plexus/static
    """
    description = 'Build version.json.'
    user_options = [
        ('base-dir=', 'b', 'base directory'),
        ('output-dir=', 'o', 'output directory'),
        ('release=', 'r', 'release number'),
        ('tag-prefix=', 't', 'tag prefix'),
        ('version=', 'v', 'Semantic version number')
    ]

    def initialize_options(self):
        """Initialize the command's options."""
        self.base_dir = getcwd()
        self.output_dir = getcwd()
        self.release = None
        self.tag_prefix = 'v'
        self.version = VERSION

    def finalize_options(self):
        """Finalize/validate the command's options."""
        if self.base_dir is None:
            raise Exception('No base directory set.')

        if self.output_dir is None:
            raise Exception('Parameter --output-dir is missing')

        if self.version is None:
            raise Exception('No version set.')

    def run(self):
        """Generate a version.json file w/project version information."""
        default = 'UNKNOWN'

        try:
            from git import Repo

            repo = Repo(path.realpath(self.base_dir))
            scm_branch = repo.active_branch.name
        except Exception:
            scm_branch = default

        try:
            commit_id = repo.head.reference.commit.hexsha
        except Exception:
            commit_id = default

        version_json = {
            'version': self.version,
            'buildDate': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + "Z",
            'deployDate': 'NOT-YET-DEPLOYED',
            'scmBranch': getenv('GIT_BRANCH', scm_branch),
            'scmLastCommit': getenv('GIT_COMMIT', commit_id)
        }

        version_path = path.abspath(self.output_dir)
        file = path.join(version_path, 'version.json')

        if not path.exists(version_path):
            makedirs(version_path)

        with open(file, 'w') as output:
            dump(version_json, output, indent=2)


VERSION = '1.0dev'

setup(
    name='dependency-1.0',
    version=VERSION,
    url='https://cdn-gitlab.363-283.io/dependency',
    author='',
    author_email='chm@maxartech.onmicrosoft.com',
    description='Super great pets!',
    long_description=__doc__,
    packages=find_packages(exclude=['tests*']),
    install_requires=[
        'fast-pymera @ git+ssh://git@cdn-gitlab.363-283.io:2252/chimera/fast-pymera.git@v0.2.8#egg=fast-pymera-0.2.8',
        'uvicorn==0.11.3',
        'aiofiles==0.4.0',
        'async-exit-stack==1.0.1',
        'async-generator==1.10',
    ],
    tests_require=[
        'pytest==5.3.5',
        'hypothesis==5.6.0',
    ],
    include_package_data=True,
    data_files=[
        ('/bin', ['pkg/dependency.sh']),
        ('/etc', ['pkg/logging.json']),
    ],
    platforms='any',
    test_suite='tests',
    cmdclass={
        'changelog': ChangelogPdfCommand,
        'version': VersionJsonCommand
    })
