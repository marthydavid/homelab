#!/usr/bin/env python3
"""Watch the Applications of one app-of-apps scenario and judge the sync-wave gate.

Polls the Argo CD Applications of a scenario once per interval, prints every state change and,
at the end, checks the property the issue is about: when a child Application of wave N+1
first showed up, were all child Applications of the lower waves already Healthy?

Exit codes: 0 gate held, 3 gate released early (the bug), 2 inconclusive (nothing to judge).
"""
import argparse
import json
import subprocess
import sys
import time

WAVE_ANNOTATION = "argocd.argoproj.io/sync-wave"


def kubectl(kubeconfig, *args):
    cmd = ["kubectl", "--kubeconfig", kubeconfig, *args]
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip())
    return out.stdout


def snapshot(kubeconfig, namespace, scenario):
    raw = kubectl(
        kubeconfig, "-n", namespace, "get", "applications",
        "-l", f"repro.homelab/scenario={scenario}", "-o", "json",
    )
    apps = {}
    for item in json.loads(raw)["items"]:
        meta, status = item["metadata"], item.get("status", {})
        wave = meta.get("annotations", {}).get(WAVE_ANNOTATION)
        op = status.get("operationState", {})
        apps[meta["name"]] = {
            "wave": int(wave) if wave is not None else None,
            "sync": status.get("sync", {}).get("status", "-"),
            "health": status.get("health", {}).get("status", "-"),
            "op": op.get("phase", "-"),
            "created": meta.get("creationTimestamp", ""),
            "conditions": [c.get("message", "") for c in status.get("conditions", [])],
            "op_message": op.get("message", ""),
        }
    return apps


def key(app):
    return (app["sync"], app["health"], app["op"])


def jobs_report(kubeconfig, namespace, scenario):
    instance = namespace.removeprefix("argocd-")
    target = f"repro-{instance}-{scenario}"
    try:
        raw = kubectl(kubeconfig, "-n", target, "get", "jobs", "-o", "json")
    except RuntimeError:
        return []
    rows = []
    for job in json.loads(raw)["items"]:
        st = job.get("status", {})
        state = "succeeded" if st.get("succeeded") else "failed" if st.get("failed") else "running"
        rows.append((job["metadata"]["name"], state, st.get("startTime", "-")))
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kubeconfig", required=True)
    ap.add_argument("--namespace", required=True)
    ap.add_argument("--scenario", required=True)
    ap.add_argument("--timeout", type=int, default=240)
    ap.add_argument("--interval", type=float, default=1.0)
    ap.add_argument("--settle", type=int, default=20, help="seconds to keep watching once all children exist")
    args = ap.parse_args()

    t0 = time.time()
    last = {}
    first_seen = {}  # child -> (offset, states of all apps in that sample)
    all_present_at = None

    print(f"watching {args.namespace} scenario={args.scenario} for up to {args.timeout}s")
    print(f"{'t+':>6}  {'application':<36} {'wave':>5}  {'sync':<10} {'health':<12} {'operation'}")

    while time.time() - t0 < args.timeout:
        try:
            apps = snapshot(args.kubeconfig, args.namespace, args.scenario)
        except RuntimeError as e:
            print(f"  (kubectl: {e})", file=sys.stderr)
            time.sleep(args.interval)
            continue
        now = time.time() - t0
        for name, app in sorted(apps.items(), key=lambda kv: (kv[1]["wave"] is not None, kv[1]["wave"] or 0, kv[0])):
            if last.get(name) != key(app):
                wave = "-" if app["wave"] is None else app["wave"]
                print(f"{now:5.0f}s  {name:<36} {wave:>5}  {app['sync']:<10} {app['health']:<12} {app['op']}")
                last[name] = key(app)
            if app["wave"] is not None and name not in first_seen:
                first_seen[name] = (now, {n: dict(a) for n, a in apps.items()})
        children = {n: a for n, a in apps.items() if a["wave"] is not None}
        # once the parent's own sync operation has finished, give the children `settle` seconds to
        # reach their final state and stop
        if children and all_present_at is None:
            root = [a for a in apps.values() if a["wave"] is None]
            if root and root[0]["op"] in ("Succeeded", "Failed", "Error"):
                all_present_at = now
        if all_present_at is not None and now - all_present_at >= args.settle:
            break
        time.sleep(args.interval)

    # ---- verdict -----------------------------------------------------------------------------
    print()
    final = snapshot(args.kubeconfig, args.namespace, args.scenario)
    kids = {n: a for n, a in final.items() if a["wave"] is not None}
    waves = sorted({a["wave"] for a in kids.values()})
    if len(waves) < 2:
        print("inconclusive: fewer than two waves of child Applications were observed")
        return 2

    early = []
    for name, app in sorted(kids.items(), key=lambda kv: kv[1]["wave"]):
        if name not in first_seen or app["wave"] == waves[0]:
            continue
        offset, sample = first_seen[name]
        for other_name, other in sample.items():
            if other["wave"] is not None and other["wave"] < app["wave"] and other["health"] != "Healthy":
                early.append((name, offset, other_name, other))

    shown = set()
    for name, app in sorted(kids.items(), key=lambda kv: kv[1]["wave"]):
        if name in first_seen:
            print(f"first seen: {name} (wave {app['wave']}) at t+{first_seen[name][0]:.0f}s")
        else:
            print(f"never created: {name} (wave {app['wave']})")
    for name, offset, other_name, other in early:
        if (name, other_name) in shown:
            continue
        shown.add((name, other_name))
        print(
            f"EARLY RELEASE: {name} appeared at t+{offset:.0f}s while {other_name} "
            f"(wave {other['wave']}) was sync={other['sync']} health={other['health']} op={other['op']}"
        )

    print("\nfinal state:")
    for name, app in sorted(final.items(), key=lambda kv: (kv[1]["wave"] is not None, kv[1]["wave"] or 0, kv[0])):
        print(f"  {name:<36} sync={app['sync']:<10} health={app['health']:<12} op={app['op']}")
        for msg in app["conditions"][:2]:
            print(f"      condition: {msg[:160]}")
        if app["op"] in ("Failed", "Error", "Running") and app["op_message"]:
            print(f"      operation: {app['op_message'][:160]}")
    jobs = jobs_report(args.kubeconfig, args.namespace, args.scenario)
    if jobs:
        print("\njobs in the workload namespace:")
        for name, state, started in jobs:
            print(f"  {name:<20} {state:<10} started {started}")

    if early:
        print("\nRESULT: sync-wave gate released early (bug reproduced)")
        return 3
    print("\nRESULT: sync-wave gate held")
    return 0


if __name__ == "__main__":
    sys.exit(main())
