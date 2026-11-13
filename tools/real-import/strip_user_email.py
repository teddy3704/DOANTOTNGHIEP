"""REAL-DATA-1: copy dlu_user.csv WITHOUT its email column, so email never reaches PostgreSQL.

Usage: python -I strip_user_email.py <in dlu_user.csv> <out csv outside the repository>
Input (no header, MySQL quoting, NULL unquoted): id, auth, deleted, username, email.
Output: id, auth, deleted, username (CSV, minimal quoting: NULL stays unquoted = SQL NULL). Prints only row counts.
"""
import csv
import sys


def main(src: str, dst: str) -> int:
    csv.field_size_limit(10**9)
    rows = 0
    with open(src, newline="", encoding="utf-8-sig") as fin, open(dst, "w", newline="", encoding="utf-8") as fout:
        out = csv.writer(fout, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        for row in csv.reader(fin):
            if len(row) != 5:
                print(f"row {rows + 1}: expected 5 columns, got {len(row)}", file=sys.stderr)
                return 2
            out.writerow(row[:4])
            rows += 1
    print(f"dlu_user rows={rows} (email column dropped)")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    sys.exit(main(sys.argv[1], sys.argv[2]))
