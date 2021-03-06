#!/bin/bash

# Remain only excess utterances once they appear more than a specified
# number of times with the same transcription, in a data set.
# E.g. useful for finding excess "uh-huh"

if [ $# != 3 ]; then
  echo "Usage: find_dup_utts.sh max-count <src-data-dir> <dest-data-dir>"
  echo "e.g.: find_dup_utts.sh 10 data/train data/train_dup"
  echo "This script is used to find out utterances that have from over-represented"
  echo "transcriptions (such as 'uh-huh'), by limiting the number of repetitions of"
  echo "any given word-sequence to a specified value.  It's often used to get"
  echo "subsets for early stages of training."
  exit 1;
fi

maxcount=$1
srcdir=$2
destdir=$3
mkdir -p $destdir

[ ! -f $srcdir/text ] && echo "$0: Invalid input directory $srcdir" && exit 1;

! mkdir -p $destdir && echo "$0: could not create directory $destdir" && exit 1;

! [ "$maxcount" -gt 1 ] && echo "$0: invalid max-count '$maxcount'" && exit 1;

cp $srcdir/* $destdir
cat $srcdir/text | \
  perl -e '
  $maxcount = shift @ARGV;
  @all = ();
   $p1 = 103349; $p2 = 71147; $k = 0;
   sub random { # our own random number generator: predictable.
     $k = ($k + $p1) % $p2;
     return ($k / $p2);
  }
  while(<>) {
    push @all, $_;
    @A = split(" ", $_);
    shift @A;
    $text = join(" ", @A);
    $count{$text} ++;
  }
  foreach $line (@all) {
    @A = split(" ", $line);
    shift @A;
    $text = join(" ", @A);
    $n = $count{$text};
    if ($n > $maxcount) {
      print $line;
    }
  }'  $maxcount >$destdir/text

echo "Reduced number of utterances from `cat $srcdir/text | wc -l` to `cat $destdir/text | wc -l`"

echo "Using fix_data_dir.sh to reconcile the other files."
utils/fix_data_dir.sh $destdir
rm -r $destdir/.backup

exit 0
