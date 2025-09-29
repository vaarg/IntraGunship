#!/bin/bash
# Usage:
#   ./parse_snaffler.sh <Rating> [inputfile]
#
# Example:
#   ./parse_snaffler.sh Red snaffler.log

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <Rating> [inputfile]" >&2
  exit 1
fi

RATING_REQ="$(echo "$1" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')"
shift
INFILE="${1:-/dev/stdin}"

perl -nE '
  if (m/^\[.*?\]\s+[0-9-]{10}\s+[0-9:]{8}Z\s+\[File\]\s+\{(Green|Yellow|Red|Black)\}\<([^>]*)\>\(([^)]*)\)\s*(.*)$/) {
    my $rating = $1;
    my $angle  = $2;
    my $path   = $3;
    my $context = $4;
    my @parts = split(/\|/, $angle);
    my $access = $parts[1] // "";
    my $creation = $parts[-1] // "";
    $context =~ s/^\s+|\s+$//g;
    say join("\t", $rating, $access, $path, $context, $creation);
  }
' "$INFILE" \
| awk -F'\t' -v want="$RATING_REQ" '
BEGIN {
  red="\033[31m"; green="\033[32m"; yellow="\033[33m"; black="\033[90m";
  cyan="\033[36m"; bold="\033[1m"; reset="\033[0m";
}
$1==want {
  rating=$1; access=$2; path=$3; context=$4; creation=$5;
  color=(rating=="Red"?red:(rating=="Yellow"?yellow:(rating=="Green"?green:black)));
  print bold "Rating: " color rating reset;
  print bold "Access: " reset access;
  print bold "Full Path: " reset path;
  print bold "Context: " cyan context reset;
  print bold "Creation Time: " reset creation;
  print "-----";
}'
