library trunk_track.commit_data;

import 'dart:collection';
import 'dart:convert';

import 'package:git/git.dart';
import 'package:trunk_track/merge_set.dart';
import 'package:trunk_track/version.dart';

/**
 * [firstCommit] defines the first SVN commit number that should be parsed. If
 * left null, the commit number for the first dev release of 1.1 (31123) is
 * used.
 */
List<TrunkCommitData> inspectCommits(LinkedHashMap<String, Commit> commits,
    {int firstCommit}) {
  if(firstCommit == null) firstCommit = _V1_1_COMMIT;

  return commits.keys
      .map((commitSha) {
    return _parseTrunkCommit(commitSha, commits[commitSha], firstCommit);
  }).where((data) => data != null).toList();
}

TrunkCommitData _parseTrunkCommit(String commitSha, Commit commit, int firstCommit) {
  var lines = const LineSplitter().convert(commit.message);

  var lineMatch = _trunkSvnIdRegExp.firstMatch(lines.last);

  var svnCommitNumber = int.parse(lineMatch[1]);

  if (svnCommitNumber < firstCommit) return null;

  var versionLine = lines.singleWhere((l) => l.startsWith(_VERSION));
  var versionStr = versionLine.substring(_VERSION.length);
  var version = new Version.parse(versionStr);

  var mergeLines = lines
      .where((line) => line.startsWith('svn merge -'))
      .toList();

  var merges = new UnmodifiableListView(
      mergeLines.map((line) => new MergeSet(line)).toList());

  return new TrunkCommitData(commitSha, svnCommitNumber, commit, merges, version);
}

class SvnCommitData {
  final String commitSha;
  final Commit commit;
  final int svnCommitNumber;

  SvnCommitData(this.commitSha, this.commit, this.svnCommitNumber);

  factory SvnCommitData.parse(String commitSha, Commit commit) {
    var lines = const LineSplitter().convert(commit.message);

    var lineMatch = _bleedingEdgeSvnIdRegExp.firstMatch(lines.last);

    var svnCommitNumber = int.parse(lineMatch[1]);

    return new SvnCommitData(commitSha, commit, svnCommitNumber);
  }

  static LinkedHashMap<int, SvnCommitData> getCommitData(
      Map<String, Commit> commits) {
    var map = new LinkedHashMap<int, SvnCommitData>();

    commits.forEach((sha, commit) {
      var data = new SvnCommitData.parse(sha, commit);
      map[data.svnCommitNumber] = data;
    });

    return map;
  }
}

class TrunkCommitData extends SvnCommitData{
  final List<MergeSet> merges;
  final Version version;

  TrunkCommitData(String commitSha, int svnCommitNumber, Commit commit,
      this.merges, this.version) : super(commitSha, commit, svnCommitNumber);

  String toString() => '$version @ $svnCommitNumber';
}

const _V1_1_COMMIT = 31123;

const _VERSION = 'Version ';

final _trunkSvnIdRegExp = new RegExp(
    r'git-svn-id: https://dart.googlecode.com/svn/trunk@(\d+) '
    '260f80e4-7a28-3924-810f-c04153c831b5');

final _bleedingEdgeSvnIdRegExp = new RegExp(
    r'git-svn-id: https://dart.googlecode.com/svn/branches/bleeding_edge@(\d+) '
    '260f80e4-7a28-3924-810f-c04153c831b5');
