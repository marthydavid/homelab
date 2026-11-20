#!/usr/bin/env python3
"""Watch the Applications of one app-of-apps scenario and judge the sync-wave gate.

The expected children and their waves come from the app-of-apps chart (not from whatever
happens to exist), so "the higher wave was never created" is a result too: it is what a
correctly holding gate looks like.

For every child of wave N+1 the question is: when it first showed up, were all children of the
lower waves already Synced *and* Healthy? The issue states the expectation as "must not start
until the lower-wave child is Synced". Health alone is not enough: the bug is precisely a child
that reports Healthy while one of its resources failed to apply (sync stays OutOfSync).

Exit codes: 0 gate held, 3 gate released early (the bug), 2 inconclusive (see the reason printed).
"""
import argparse
import json
import re
import subprocess
import sys
import time

WAVE_ANNOTATION = "argocd.argoproj.io/sync-wave"


def run(cmd):
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip())
    return out.stdout


def kubectl(kubeconfig, *args):
    return run(["kubectl", "--kubeconfig", kubeconfig, *args])


def expected_children(chart, scenario, instance):
    """[(application name, wave)] as rendered by the app-of-apps chart."""
    rendered = run(["helm", "template", "t", chart, "--set", f"scenario={scenario}", "--set", f"instance={instance}"])
    kids = []
    for doc in rendered.split("\n---\n"):
        name = re.search(r"^  name: (\S+)", doc, re.M)
        wave = re.search(r'sync-wave: "(-?\d+)"', doc)
        if name and wave:
            kids.append((name.group(1), int(wave.group(1))))
    return kids


def snapshot(kubeconfig, namespace, scenario):
    raw = kubectl(kubeconfig, "-n", namespace, "get", "applications", "-l", f"repro.homelab/scenario={scenario}", "-o", "json")
    apps = {}
    for item in json.loads(raw)["items"]:
        meta, spec, status = item["metadata"], item.get("spec", {}), item.get("status", {})
        wave = meta.get("annotations", {}).get(WAVE_ANNOTATION)
        op = status.get("operationState", {})
        apps[meta["name"]] = {
            "wave": int(wave) if wave is not None else None,
            "sync": status.get("sync", {}).get("status", "-"),
            "health": status.get("health", {}).get("status", "-"),
            "op": op.get("phase", "-"),
            "op_message": op.get("message", ""),
            "dest_ns": spec.get("destination", {}).get("namespace"),
            "resource_ns": sorted({r.get("namespace") for r in status.get("resources", []) if r.get("namespace")}),
        }
    return apps


def settled(app):
    """What a wave gate should require of a lower-wave child."""
    return app is not None and app["health"] == "Healthy" and app["sync"] == "Synced"


def state_key(app):
    return (app["sync"], app["health"], app["op"])


def jobs_report(kubeconfig, namespace, scenario):
    target = f"repro-{namespace.removeprefix('argocd-')}-{scenario}"
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
    ap.add_argument("--namespace", required=True, help="namespace of the Argo CD instance, argocd-<instance>")
    ap.add_argument("--scenario", required=True)
    ap.add_argument("--chart", required=True, help="path of the app-of-apps chart")
    ap.add_argument("--timeout", type=int, default=240)
    ap.add_argument("--interval", type=float, default=1.0)
    ap.add_argument("--settle", type=int, default=20, help="seconds to keep watching once the parent finished")
    args = ap.parse_args()

    instance = args.namespace.removeprefix("argocd-")
    expected = expected_children(args.chart, args.scenario, instance)
    waves = sorted({w for _, w in expected})
    if len(waves) < 2:
        print("inconclusive: the chart renders fewer than two waves")
        return 2
    wave_of = dict(expected)

    t0 = time.time()
    last, first_seen = {}, {}  # first_seen: child -> (offset, states of all apps in that sample)
    parent_done_at = None
    print(f"watching {args.namespace} scenario={args.scenario} for up to {args.timeout}s")
    print("expected children: " + ", ".join(f"{n} (wave {w})" for n, w in sorted(expected, key=lambda x: x[1])))
    print(f"{'t+':>6}  {'application':<40} {'wave':>5}  {'sync':<10} {'health':<12} {'operation'}")

    while time.time() - t0 < args.timeout:
        try:
            apps = snapshot(args.kubeconfig, args.namespace, args.scenario)
        except RuntimeError as e:
            print(f"  (kubectl: {e})", file=sys.stderr)
            time.sleep(args.interval)
            continue
        now = time.time() - t0
        for name, app in sorted(apps.items(), key=lambda kv: (kv[1]["wave"] is not None, kv[1]["wave"] or 0, kv[0])):
            if last.get(name) != state_key(app):
                wave = "-" if app["wave"] is None else app["wave"]
                print(f"{now:5.0f}s  {name:<40} {wave:>5}  {app['sync']:<10} {app['health']:<12} {app['op']}")
                last[name] = state_key(app)
            if app["wave"] is not None and name not in first_seen:
                first_seen[name] = (now, {n: dict(a) for n, a in apps.items()})
        root = [a for a in apps.values() if a["wave"] is None]
        if parent_done_at is None and root and root[0]["op"] in ("Succeeded", "Failed", "Error"):
            parent_done_at = now
        if parent_done_at is not None and now - parent_done_at >= args.settle:
            break
        time.sleep(args.interval)

    final = snapshot(args.kubeconfig, args.namespace, args.scenario)
    print("\nfinal state:")
    for name, app in sorted(final.items(), key=lambda kv: (kv[1]["wave"] is not None, kv[1]["wave"] or 0, kv[0])):
        print(f"  {name:<40} sync={app['sync']:<10} health={app['health']:<12} op={app['op']}")
        if app["op_message"] and app["op"] in ("Running", "Failed", "Error"):
            print(f"      operation: {app['op_message'][:170]}")
    jobs = jobs_report(args.kubeconfig, args.namespace, args.scenario)
    if jobs:
        print("\njobs in the workload namespace:")
        for name, state, started in jobs:
            print(f"  {name:<24} {state:<10} started {started}")

    # ---- isolation: an instance must only ever see resources of its own destination namespace ----
    leaks = [(n, a["resource_ns"], a["dest_ns"]) for n, a in final.items() if any(ns != a["dest_ns"] for ns in a["resource_ns"])]
    if leaks:
        for n, rns, dest in leaks:
            print(f"\nISOLATION BROKEN: {n} lists resources in {rns}, destination is {dest}")
        print("RESULT: inconclusive (another Argo CD instance is interfering)")
        return 2

    # ---- verdict ------------------------------------------------------------------------------
    print()
    early, held = [], []
    for name, wave in sorted(expected, key=lambda x: x[1]):
        if wave == waves[0]:
            continue
        lower = [n for n, w in expected if w < wave]
        if name in first_seen:
            offset, sample = first_seen[name]
            bad = [(n, sample.get(n)) for n in lower if not settled(sample.get(n))]
            print(f"{name} (wave {wave}) first seen at t+{offset:.0f}s")
            for n, a in bad:
                state = "did not exist yet" if a is None else f"sync={a['sync']} health={a['health']} op={a['op']}"
                print(f"  EARLY RELEASE: {n} (wave {wave_of[n]}) {state}")
                early.append(name)
        else:
            unhealthy = [n for n in lower if not settled(final.get(n))]
            if unhealthy:
                print(f"{name} (wave {wave}) was never created, {', '.join(unhealthy)} not Synced and Healthy: the gate held")
                held.append(name)
            else:
                print(f"{name} (wave {wave}) was never created although every lower wave is Synced and Healthy")
                print("RESULT: inconclusive (the gate is stuck for another reason)")
                return 2

    if early:
        print("\nRESULT: sync-wave gate released early (bug reproduced)")
        return 3
    if lowest := [n for n, w in expected if w == waves[0]]:
        if not any(n in first_seen for n in lowest):
            print("\nRESULT: inconclusive (the lowest wave never appeared)")
            return 2
    print("\nRESULT: sync-wave gate held")
    return 0


if __name__ == "__main__":
    sys.exit(main())
