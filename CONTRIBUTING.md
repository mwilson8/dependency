# Contributing

Contributions to *dependency* are welcome! If you find a bug or have an idea
for enhancements, please report them through the [issue tracker]. Code changes
should be submitted as a merge request.

[issue tracker]: https://cdn-gitlab.363-283.io/chimera/file-service/issues


## Before You Begin

*dependency* is a Python 3 application. Instructions for setting up a development
environment can be found in [README.md](README.md).

> *NOTE*: It is highly recommmend that you use
> [PyEnv](https://github.com/yyuu/pyenv),
> [Virtualenv](https://virtualenv.pypa.io/), and
> [Virtualenvwrapper](https://virtualenvwrapper.readthedocs.org/) to ensure a
> clean development environment.

You will also need to establish a 363-283.io account to report issues and/or
make changes.


## Making Changes

* Create a topic branch for your work

    * This branch should typically be branched from *develop*

        To create a branch from *develop*: `git checkout -b feature/short-description develop`

    * Use the following naming convention for your branch name:

            topic/short-hyphenated-description

        Where `topic` is something like "feature" or "fix".

* Run the linter

    Take note of the output of the linter before and after you make changes.
    Ideally, your changes will not make the score lower.

        $ python setup.py lint


* Use the following format for commit messages:

        Short description (50 characters or less).
    
        Detailed description, if neccessary, preceded with a blank line. Wrap
        the detailed description at 72 characters. The blank line separates the
        short description from the longer description allowing for better
        integration with a variety of tools (e.g. `git log --oneline`).


## Submitting Changes For Review

* Update the CHANGELOG

    All notable changes to this project should be documented
    [CHANGELOG.md](CHANGELOG.md) file. Changelog entries should be kept at a
    high level with users being the target audience.

    The format of the CHANGELOG.md file is based on [Keep a Changelog] and this
    project adheres to [Semantic Versioning].

* Push your topic branch to GitLab

* Submit a Merge Request

    * Include a detailed description of how to test the changes.
    * Include the ticket number and/or a link to the ticket.

* Gather feedback through GitLab's merge request tool

[Keep a Changelog]: http://keepachangelog.com/en/1.0.0/
[Semantic Versioning]: http://semver.org/spec/v2.0.0.html


## Reviewing Merge Requests

* Checkout the topic branch

* Follow the test instructions provided in the merge request

* Use GitLab to comment on the merge request if you have any questions or concerns

* Use your best judgement before approving merge requests

    * If you are satisfied with the changes, add your stamp of approval.

        You can do this by clicking the *thumbs up* button on the merge requests.

    * Merge the changes into the target branch

        If GitLab can handle the merge automatically, you will be presented with
        a "Accept Merge Request" button and an option to delete the feature
        branch (you should probably check that box). Otherwise if there is a
        conflict, you (or the creator of the merge request) will need to resolve
        those conflicts. and try again.
