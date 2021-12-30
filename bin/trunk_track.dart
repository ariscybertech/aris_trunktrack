library trunk_track;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:git/git.dart';
import 'package:path/path.dart' as p;
import 'package:trunk_track/commit_data.dart';
import 'package:trunk_track/merge_set.dart';
import 'package:trunk_track/version.dart';

void main() {
  var currentDir = p.current;

  GitDir gitDir;

  GitDir.fromExisting(currentDir)
    .then((value) {
      gitDir = value;
      return gitDir.getCommits(_TRUNK_BRARCH);
    }).then((commits) {
      var data = inspectCommits(commits);

      var v1_2Items = data.where((cd) => cd.version > _V1_2)
          .where((cd) => cd.version < _V1_3);

      return _getData(gitDir, v1_2Items);
    }).then((Map<int, SvnCommitData> data) {

      var allBugs = new Set<int>();

      data.forEach((k, SvnCommitData v) {
        assert(v != null);

        var bugs = _getBugs(v.commit.message);

        allBugs.addAll(bugs);

      });

      print('Bugs fixed: ${allBugs.length}');

      print(allBugs.join(','));

    });
}

List<int> _getBugs(String message) {
  var lines = const LineSplitter().convert(message);

  var bugLines = lines
      .map((l) => l.trim())
      .where((l) => l.startsWith('BUG'))
      .toList();

  if(bugLines.isNotEmpty) {
    bugLines = bugLines.map(_parseBugLine).where((l) => l != null).toList();
    return bugLines;
  }

  return [];
}

int _parseBugLine(String bugLine) {
  assert(bugLine.startsWith('BUG'));
  if(bugLine == 'BUG=') return null;

  var match = _fullBugUrlRegExp.firstMatch(bugLine);
  if(match != null) {
    return int.parse(match[3]);
  }

  match = _simpleBugRegExp.firstMatch(bugLine);
  if(match != null) {
    return int.parse(match[2]);
  }

  match = _sillyBugRegExp.firstMatch(bugLine);
  if(match != null) {
    return int.parse(match[1]);
  }

  throw new UnsupportedError('Could not parse bug line:\t$bugLine');
}

Future<Map<int, SvnCommitData>> _getData(GitDir gitDir, Iterable<TrunkCommitData> commitDataList) {
  var sets = commitDataList.expand((TrunkCommitData cd) => cd.merges);

  var commits = MergeSet.getCommitIds(sets);

  print('Total commits: ${commits.length}');

  return _getBleedingEdgeCommitData(gitDir)
      .then((bleedingEdgeCommits) {
        var map = new LinkedHashMap();

        for(var commit in commits) {
          var commitData = bleedingEdgeCommits[commit];
          if(commitData != null) {
            map[commit] = commitData;
          }
        }

        return map;
      });
}

Future<Map<int, SvnCommitData>> _getBleedingEdgeCommitData(GitDir gitDir) =>
    gitDir.getCommits(_BLEEDING_EDGE_BRANCH).then(SvnCommitData.getCommitData);

const _BLEEDING_EDGE_BRANCH = 'remotes/origin/master';
const _TRUNK_BRARCH = 'remotes/trunk/master';

final _V1_2 = new Version(1,  2,  0);

final _V1_3 = new Version(1, 3, 0);

final _fullBugUrlRegExp = new RegExp(
    r'BUGS?= ?(https?://)?(code.google.com/p/dart/issues/detail\?id=|dartbug.com/|www.dartbug.com/)(\d+)');

final _simpleBugRegExp = new RegExp(r'BUG=(dart:)?(\d+)');

final _sillyBugRegExp = new RegExp(r'BUG: (\d+)');

