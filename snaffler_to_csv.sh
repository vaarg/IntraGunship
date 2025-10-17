#!/bin/bash
# Usage:
#   ./parse_snaffler_to_csv.sh [inputfile] [outputfile]
#
# Example:
#   ./parse_snaffler_to_csv.sh snaffler.log output.csv
#   ./parse_snaffler_to_csv.sh snaffler.log  # Outputs to stdout

set -euo pipefail

# Check arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 [inputfile] [outputfile]" >&2
  echo "  inputfile: Snaffler log file (default: stdin)" >&2
  echo "  outputfile: CSV output file (default: stdout)" >&2
  exit 1
fi

INFILE="${1:-/dev/stdin}"
OUTFILE="${2:-/dev/stdout}"

# Write CSV header
echo "Rating,Access,Full Path,Context,Creation Time" > "$OUTFILE"

# Parse Snaffler output and produce CSV
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
    $context =~ s/"/""/g;  # Escape double quotes for CSV
    say join(",", $rating, "\"$access\"", "\"$path\"", "\"$context\"", "\"$creation\"");
  }
' "$INFILE" >> "$OUTFILE"
