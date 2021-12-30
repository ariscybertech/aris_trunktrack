library trunk_track.merge_set;

import 'dart:collection';

abstract class MergeSet {
  int get firstCommit;
  int get lastCommit;
  bool get isRevert;
  bool containsCommit(int commitNumber);

  factory MergeSet(String line) {
    assert(line.startsWith('svn merge -'));

    var commitMergeMatch = _commitMergeRegExp.firstMatch(line);
    if (commitMergeMatch != null) {
      int mergeCommitNumber = int.parse(commitMergeMatch[1]);
      return new SingleCommitMerge(mergeCommitNumber);
    }

    var rangeMergeMatch = _rangeMergeRegExp.firstMatch(line);
    if (rangeMergeMatch != null) {
      int rangeStart = int.parse(rangeMergeMatch[1]);
      int rangeEnd = int.parse(rangeMergeMatch[2]);

      return new RangeMerge(rangeStart, rangeEnd);
    }

    var revertCommitMergeMatch = _revertCommitMergeRegExp.firstMatch(line);
    if (revertCommitMergeMatch != null) {
      int mergeCommitNumber = int.parse(revertCommitMergeMatch[1]);
      return new RevertCommitMerge(mergeCommitNumber);
    }

    throw new StateError('Not supported: $line');
  }

  static Set<int> getCommitIds(Iterable<MergeSet> sets) {
    var commits = new SplayTreeSet<int>();
    var reverts = new Set<int>();

    for (var set in sets) {
      for (var i = set.firstCommit; i <= set.lastCommit; i++) {
        if (set.isRevert) {
          reverts.add(i);
        } else {
          commits.add(i);
        }
      }
    }

    for(var revert in reverts) {
      if(!commits.remove(revert)) {
        throw 'Could not find reverted commit $revert';
      }
    }

    return commits;
  }
}

class SingleCommitMerge implements MergeSet {
  final int commit;
  bool get isRevert => false;

  SingleCommitMerge(this.commit) {
    assert(commit != null && commit >= 0);
  }

  int get firstCommit => commit;
  int get lastCommit => commit;
  bool containsCommit(int commitNumber) => commitNumber == commit;
}

class RevertCommitMerge implements MergeSet {
  final int commit;
  bool get isRevert => true;

  RevertCommitMerge(this.commit) {
    assert(commit != null && commit >= 0);
  }

  int get firstCommit => commit;
  int get lastCommit => commit;
  bool containsCommit(int commitNumber) => commitNumber == commit;
}

class RangeMerge implements MergeSet {
  final int firstCommit;
  final int lastCommit;
  bool get isRevert => false;

  bool containsCommit(int commitNumber) =>
      commitNumber >= firstCommit && commitNumber <= lastCommit;

  RangeMerge(this.firstCommit, this.lastCommit) {
    assert(firstCommit < lastCommit);
    assert(firstCommit >= 0);
  }
}

const _BLEEDING_EDGE =
    'https://dart.googlecode.com/svn/branches/bleeding_edge trunk';

final _commitMergeRegExp = new RegExp(r'svn merge -c (\d+) ' + _BLEEDING_EDGE);
final _revertCommitMergeRegExp = new RegExp(r'svn merge -c -(\d+) ' + _BLEEDING_EDGE);
final _rangeMergeRegExp = new RegExp(r'svn merge -r ?(\d+):(\d+) ' + _BLEEDING_EDGE);
