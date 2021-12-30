#trunk_track

The code assumes it is run at the root of a git repository pointing to the
Dart source code with two remotes.

`origin` should point to https://chromium.googlesource.com/external/dart/bleeding_edge

`trunk` should point to https://chromium.googlesource.com/external/dart

Here's a section from `.git/config`


```
[remote "origin"]
  url = https://chromium.googlesource.com/external/dart/bleeding_edge
  fetch = +refs/heads/*:refs/remotes/origin/*
[remote "trunk"]
  url = https://chromium.googlesource.com/external/dart
  fetch = +refs/heads/*:refs/remotes/trunk/*
```
