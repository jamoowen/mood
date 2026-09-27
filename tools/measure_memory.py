#!/usr/bin/env python3
import datetime
import subprocess
import sys


def parse_lstart(s):
    parts = s.strip().split()
    if len(parts) != 5:
        return None
    day = parts[1].zfill(2)
    try:
        return datetime.datetime.strptime(
            f"{parts[0]} {day} {parts[2]} {parts[3]} {parts[4]}",
            "%a %d %b %H:%M:%S %Y",
        )
    except ValueError:
        return None


def ps_table():
    out = subprocess.run(
        ["ps", "-axo", "pid=,ppid=,rss=,ucomm=,lstart="],
        capture_output=True, text=True,
    ).stdout
    table = {}
    for line in out.splitlines():
        parts = line.split(None, 4)
        if len(parts) < 5:
            continue
        try:
            pid, ppid, rss = int(parts[0]), int(parts[1]), int(parts[2])
        except ValueError:
            continue
        start = parse_lstart(parts[4])
        if start is None:
            continue
        table[pid] = (ppid, rss, parts[3].strip(), start.timestamp())
    return table


def find_mood_pids(table):
    return [pid for pid, (_, _, comm, _) in table.items()
            if comm == "Mood"]


def main():
    table = ps_table()
    mood_pids = find_mood_pids(table)
    if not mood_pids:
        print("Mood app not running. Launch it first (make run).")
        sys.exit(1)

    # WebKit helpers are reparented to launchd on modern macOS, so they can't be
    # found via PPID. They are spawned within a couple of seconds of the app, so
    # attribute by start-time proximity.
    mood_start = min(table[pid][3] for pid in mood_pids)
    app_rss = sum(table[pid][1] for pid in mood_pids)

    helpers = []
    for pid, (_, rss, comm, start) in table.items():
        if "WebKit" not in comm:
            continue
        if 0 <= (start - mood_start) <= 5:
            helpers.append((pid, rss, comm))

    helper_rss = sum(r for _, r, _ in helpers)
    total = app_rss + helper_rss

    rows = sorted(
        [(pid, table[pid][1], table[pid][2]) for pid in mood_pids] + helpers,
        key=lambda r: -r[1],
    )
    print(f"{'PID':>7} {'RSS(MB)':>9}  PROCESS")
    for pid, rss, comm in rows:
        print(f"{pid:>7} {rss / 1024:>9.1f}  {comm}")

    print()
    print(f"Mood app process RSS: {app_rss / 1024:.1f} MB")
    print(f"WebKit helper processes attributed to Mood: {len(helpers)}  "
          f"RSS: {helper_rss / 1024:.1f} MB")
    print(f"TOTAL RSS (app + WebKit helpers): {total / 1024:.1f} MB")


if __name__ == "__main__":
    main()
