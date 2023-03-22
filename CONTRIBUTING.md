# Contributing <!-- omit in toc -->

The Cartographer project team welcomes contributions from the community. If you
wish to contribute code and you have not signed our contributor license
agreement (CLA), our bot will update the issue when you open a Pull Request.
For any questions about the CLA process, please refer to our
[FAQ](https://cla.vmware.com/faq).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Packaging new versions of Cartographer](#packaging-new-versions-of-cartographer)
  - [1. `vendir` update update](#1-vendir-update-update)
  - [2. `vendir sync`](#2-vendir-sync)
  - [3. Pull request](#3-pull-request)
  - [4. Tag](#4-tag)
  - [Promote the release](#promote-the-release)
- [Contribution Flow](#contribution-flow)
  - [Staying In Sync With Upstream](#staying-in-sync-with-upstream)
  - [Updating pull requests](#updating-pull-requests)
  - [Code Style](#code-style)
  - [Formatting Commit Messages](#formatting-commit-messages)
- [Reporting Bugs and Creating Issues](#reporting-bugs-and-creating-issues)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Packaging new versions of Cartographer

To make a new version of Cartographer available via this packaging mechanism,
the following steps must be followed:

### 1. `vendir` update update 

Update [`./vendir.yaml`](./vendir.yaml) to
point at the new release of Cartographer


```scala
.
├── ...
├── src
│   └── cartographer
│       └── config
│           ├── ...
│           └── upstream
│               ├── cartographer
│               │   └── cartographer.yaml                                                     """ vendir'ed file """
│               └── cartographer-conventions
│                   └── cartographer-conventions-v0.1.0-build.1.yaml                          """ vendir'ed file """
├── tests
│   ├── ...
│   ├── 01-test-convention-setup
│   │   └── cartographer-conventions-samples-convention-server-v0.1.0-build.1.yaml            """ vendir'ed file """
│   ├── ...
├── vendir.lock.yml
└── vendir.yml            """ this file """
```

In order to gather the latest updates from Cartographer, this repository makes
use of [vendir](https://github.com/vmware-tanzu/carvel-vendir) to fetch the
desired contents from the [cartographer
repository](https://github.com/vmware-tanzu/cartographer).

Given that with `vendir` we must point at a specific version, we need to update
the file where that version is inserted to point at the latest one.

For instance, assuming a bump of Cartographer from `0.2.1` to `0.2.2`, we'd
patch the `tag`:

```diff
+++ b/vendir.yml
@@ -20,6 +20,6 @@ directories:
       - path: '.'
         githubRelease:
           disableAutoChecksumValidation: true
-          tag: v0.2.1
+          tag: v0.2.2
           assetNames: ["cartographer.yaml"]
           slug: vmware-tanzu/cartographer
```


### 2. `vendir sync`

Run `vendir sync` from the `./vendir.yml`

With `vendir.yml` pointing at the right place, `vendir sync` takes care of
fetching the assets we want and then placing them in the right place
(`./upstream`).

### 3. `make copyright check`

Run `make copyright check`. This will ensure that the generated files in
`./src/cartographer/config/upstream` are formatted with the appropriate license.
It will also ensure that the yaml is properly formatted and linted.

### 4. Pull request

Having the upstream directory up to date, create a new pull request with the
changes. 

GitHub actions will take care of packaging it all up and making sure (by
running e2e tests) that everything is working as expected.


### 5. Tag

Once merged, tag the commit with the desired version (for instance, in
our example, `v0.2.2`) and push - GitHub actions will then take care of
creating a new draft release named after the tag (location:
https://github.com/vmware-tanzu/package-for-cartographer/releases).


### Promote the release

With the draft release available, if everything is good to go, promote the
draft release to a public release.


## Contribution Flow

This is a rough outline of what a contributor's workflow looks like:

- Create a topic branch from where you want to base your work
- Make commits of logical units
- Make sure your commit messages are in the proper format (see below)
- Push your changes to a topic branch in your fork of the repository
- Submit a pull request

Example:

``` shell
git remote add upstream https://github.com/vmware-tanzu/package-for-cartographer.git
git checkout -b my-new-feature main
git commit -a
git push origin my-new-feature
```


### Staying In Sync With Upstream

When your branch gets out of sync with the vmware/main branch, use the
following to update:

``` shell
git checkout my-new-feature
git fetch -a
git pull --rebase upstream main
git push --force-with-lease origin my-new-feature
```


### Updating pull requests

If your PR fails to pass CI or needs changes based on code review, you'll most
likely want to squash these changes into existing commits.

If your pull request contains a single commit or your changes are related to
the most recent commit, you can simply amend the commit.

``` shell
git add .
git commit --amend
git push --force-with-lease origin my-new-feature
```

If you need to squash changes into an earlier commit, you can use:

``` shell
git add .
git commit --fixup <commit>
git rebase -i --autosquash main
git push --force-with-lease origin my-new-feature
```

Be sure to add a comment to the PR indicating your new changes are ready to
review, as GitHub does not generate a notification when you git push.


### Code Style

### Formatting Commit Messages

We follow the conventions on [How to Write a Git Commit
Message](http://chris.beams.io/posts/git-commit/).

Be sure to include any related GitHub issue references in the commit message.
See [GFM
syntax](https://guides.github.com/features/mastering-markdown/#GitHub-flavored-markdown)
for referencing issues and commits.


## Reporting Bugs and Creating Issues

When opening a new issue, try to roughly follow the commit message format
conventions above.


