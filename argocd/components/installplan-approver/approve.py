"""Approve OLM InstallPlans up to the startingCSV pinned in git, as an Argo CD PostSync hook.

Runs in one operator namespace (NAMESPACE). For every Subscription there with a startingCSV:
  - installed CSV == pin: nothing to do;
  - otherwise wait (up to WAIT_PLAN s) for OLM's pending InstallPlan, approve it if every CSV in
    it is not newer than its Subscription's pin, then wait (up to WAIT_CSV s) until the pinned
    CSV is installed and Succeeded.
Exits non-zero if the upgrade doesn't happen, so the Argo CD sync shows it as failed.
"""
import json, os, re, subprocess, sys, time

NS = os.environ["NAMESPACE"]
WAIT_PLAN = int(os.environ.get("WAIT_PLAN", "600"))
WAIT_CSV = int(os.environ.get("WAIT_CSV", "900"))


def kubectl(*args):
    return subprocess.run(["kubectl", "-n", NS, *args], check=True, capture_output=True, text=True).stdout


def get(kind):
    return json.loads(kubectl("get", kind, "-o", "json"))["items"]


def split(csv):
    # "lvms-operator.v4.21.2" -> ("lvms-operator", "4.21.2"); "nfd.4.21.0-2026..." -> ("nfd", ...)
    m = re.match(r"^(.*?)\.v?(\d.*)$", csv or "")
    return (m.group(1), m.group(2)) if m else (csv, "")


def newer(a, b):
    ka = [int(p) if p.isdigit() else p for p in re.split(r"[.\-+]", a)]
    kb = [int(p) if p.isdigit() else p for p in re.split(r"[.\-+]", b)]
    try:
        return ka > kb
    except TypeError:  # mixed str/int parts
        return a > b


def log(msg):
    print(f"[{NS}] {msg}", flush=True)


def pending_subs():
    out = []
    for s in get("subscriptions.operators.coreos.com"):
        pin = s["spec"].get("startingCSV")
        installed = s.get("status", {}).get("installedCSV")
        if pin and installed != pin:
            out.append((s["metadata"]["name"], pin, installed))
    return out


def pins():
    return {split(s["spec"]["startingCSV"])[0]: split(s["spec"]["startingCSV"])[1]
            for s in get("subscriptions.operators.coreos.com") if s["spec"].get("startingCSV")}


todo = pending_subs()
if not todo:
    log("all Subscriptions are at their pinned startingCSV")
    sys.exit(0)
for name, pin, installed in todo:
    log(f"{name}: installed {installed}, pinned {pin}")

deadline = time.time() + WAIT_PLAN
approved = set()
while time.time() < deadline:
    p = pins()
    for plan in get("installplans.operators.coreos.com"):
        pname = plan["metadata"]["name"]
        if plan["spec"].get("approved") or pname in approved:
            continue
        csvs = plan["spec"].get("clusterServiceVersionNames", [])
        bad = [c for c in csvs if split(c)[0] not in p or newer(split(c)[1], p[split(c)[0]])]
        if csvs and not bad:
            kubectl("patch", "installplans.operators.coreos.com", pname, "--type=merge",
                    "-p", '{"spec":{"approved":true}}')
            approved.add(pname)
            log(f"approved {pname}: {', '.join(csvs)}")
        else:
            log(f"not approving {pname}: {', '.join(bad) or 'no CSVs'} not covered by a pin")
    if approved:
        break
    time.sleep(15)

if not approved:
    log(f"no InstallPlan up to the pin appeared within {WAIT_PLAN}s (is the pinned CSV in the subscribed channel?)")
    sys.exit(1)

deadline = time.time() + WAIT_CSV
while time.time() < deadline:
    left = pending_subs()
    csvs = {c["metadata"]["name"]: c.get("status", {}).get("phase")
            for c in get("clusterserviceversions.operators.coreos.com")}
    if not left and all(csvs.get(pin) == "Succeeded" for _, pin, _ in todo):
        log("upgrade done: " + ", ".join(pin for _, pin, _ in todo))
        sys.exit(0)
    time.sleep(15)

log("upgrade did not finish in time: " + ", ".join(f"{n} at {i}" for n, _, i in pending_subs()))
sys.exit(1)
