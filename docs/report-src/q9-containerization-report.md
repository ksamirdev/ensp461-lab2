# Question 9 - Containerization and orchestration report

> Question 9: Prepare a containerization and orchestration report describing the architecture, deployment strategy, scaling results, and observations with screenshots.

Executed on an Ubuntu 24.04.5 LTS OrbStack machine (`ensp461-lab2`, arm64).
Source, logs and screenshots: <https://github.com/ksamirdev/ensp461-lab2>.

## 1. Objective

Package a small web service as a container image, run it alone and with a Redis dependency, deploy it to a Kubernetes cluster with zero-downtime updates, and automate the path from `git push` to a verified running version.

## 2. Tools and environment

| Component | Version |
|---|---|
| Host | Ubuntu 24.04.5 LTS, OrbStack machine `ensp461-lab2`, arm64 |
| Docker Engine / Compose / Buildx | 29.9.3 / v5.7.0 / v0.38.1 |
| Minikube / Kubernetes / kubectl | v1.39.0 (docker driver, containerd 2.3.4) / v1.37.0 / v1.37.2 |
| Jenkins | 2.580.2 LTS on OpenJDK 21.0.12, systemd service |
| Registry | Distribution `registry:2`, `localhost:5001` (host) and `lab2-registry:5000` (cluster) |
| Application | Python 3.12, Flask 3.1, gunicorn 23, Redis 7 |

## 3. Architecture

<svg viewBox="0 0 760 330" width="100%" xmlns="http://www.w3.org/2000/svg" font-family="Helvetica, Arial, sans-serif" font-size="12">
  <defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#333"/></marker></defs>
  <g fill="#f4f4f2" stroke="#555">
    <rect x="10" y="20" width="110" height="46" rx="6"/>
    <rect x="160" y="20" width="130" height="46" rx="6"/>
    <rect x="330" y="20" width="160" height="46" rx="6"/>
    <rect x="530" y="20" width="220" height="46" rx="6"/>
    <rect x="120" y="120" width="630" height="196" rx="8" fill="#fbfbfa" stroke-dasharray="5 3"/>
    <rect x="140" y="160" width="160" height="60" rx="6"/>
    <rect x="330" y="150" width="260" height="150" rx="6" fill="#eef3f8"/>
    <rect x="345" y="190" width="70" height="40" rx="5" fill="#fff"/>
    <rect x="425" y="190" width="70" height="40" rx="5" fill="#fff"/>
    <rect x="505" y="190" width="70" height="40" rx="5" fill="#fff"/>
    <rect x="345" y="248" width="230" height="36" rx="5" fill="#fff"/>
    <rect x="610" y="160" width="125" height="60" rx="6"/>
  </g>
  <g fill="#1b1b1b" text-anchor="middle">
    <text x="65" y="40" font-weight="bold">Developer</text><text x="65" y="56">git push</text>
    <text x="225" y="40" font-weight="bold">GitHub</text><text x="225" y="56" font-size="10.5">ksamirdev/ensp461-lab2</text>
    <text x="410" y="40" font-weight="bold">Jenkins CD</text><text x="410" y="56">poll H/2, test, build</text>
    <text x="640" y="40" font-weight="bold">lab2-registry (registry:2)</text><text x="640" y="56">ensp461-lab2:2.1.N</text>
    <text x="220" y="185" font-weight="bold">NodePort Service</text><text x="220" y="201">lab2-web :30080</text>
    <text x="460" y="172" font-weight="bold">Deployment lab2-web (RollingUpdate)</text>
    <text x="380" y="214">pod</text><text x="460" y="214">pod</text><text x="540" y="214">pod</text>
    <text x="460" y="270">ConfigMap lab2-config, probes, preStop</text>
    <text x="672" y="185" font-weight="bold">kubelet pull</text><text x="672" y="201">from registry</text>
  </g>
  <text x="135" y="140" fill="#555">Minikube node (Docker network "minikube", 192.168.49.2)</text>
  <g stroke="#333" fill="none" marker-end="url(#a)">
    <line x1="120" y1="43" x2="158" y2="43"/>
    <line x1="290" y1="43" x2="328" y2="43"/>
    <line x1="490" y1="43" x2="528" y2="43"/>
    <path d="M410,66 L410,100 L250,100 L250,158"/>
    <line x1="300" y1="190" x2="343" y2="208"/>
    <line x1="640" y1="66" x2="672" y2="158"/>
    <line x1="610" y1="200" x2="577" y2="208"/>
  </g>
  <text x="262" y="116" fill="#333">kubectl apply (rendered manifest)</text>
</svg>

<p style="text-align:center;font-size:8.8pt;color:#444">Fig: Containerization and orchestration architecture</p>

A push to `main` is detected by Jenkins SCM polling.
The pipeline runs the unit tests, builds `ensp461-lab2:2.1.<build>`, pushes it to the self-hosted registry, applies the manifests with that image, waits for the rollout and checks `/health` reports the new version.
The kubelet on the Minikube node pulls the image from the same registry over the `minikube` Docker network.
Users reach the pods through a NodePort Service that only routes to pods passing the readiness probe.

## 4. Containerization

- `docker/Dockerfile`: slim Python base, dependencies before source for caching, non-root user (uid 10001), `HEALTHCHECK`, version as a build argument.
- Image: 227 MB, 9 filesystem layers; the app's own layers add about 20 MB.
- `docker/docker-compose.yml`: web and Redis, health-gated start order, named volume for Redis data.
- Storage (Q3): writable layer lost with the container; named volume and bind mount persist.
- Networking (Q4): name resolution only on user-defined networks; separate networks are isolated.

![Container run: HTTP responses, non-root user, healthy status](docs/screenshots/q1-run.png)

## 5. Deployment strategy

`RollingUpdate` with `maxSurge: 1` and `maxUnavailable: 0`, readiness and liveness probes on `/health`, and a `preStop` sleep of 5 s.

| Operation | Without preStop | With preStop |
|---|---|---|
| Rolling update 2.0.0 to 2.0.1 | 29 ok, 5 failed | 61 ok, 0 failed |
| Rollback | 80 ok, 2 failed | 30 ok, 0 failed |
| Bad image (`9.9.9-missing`) | | rollout stalled, old pods kept serving, no outage |

`maxUnavailable: 0` alone kept capacity but not correctness: terminating pods stopped serving while still receiving traffic.
Draining with `preStop` removed every failed request in the measurement.
Rollback is `kubectl rollout undo`, which scales the previous ReplicaSet back up.

![Bad image stalls the rollout; rollback to revision 1](docs/screenshots/q6-bad-rollback.png)

## 6. Scaling results

| Command | Result |
|---|---|
| `kubectl scale --replicas=6` | 6/6 ready, 3 new pods ready within the rollout wait |
| `kubectl scale --replicas=2` | 2/2, the newest pods removed first |
| `kubectl scale --replicas=3` | back to 3/3 |

Scaling changes only the replica count, so pods keep the same ReplicaSet hash and no new revision is recorded.

![Scaling out and in](docs/screenshots/q6-scaling.png)

## 7. Continuous deployment

| Build | Trigger | Version | Result |
|---|---|---|---|
| #1 | SCM change | | ABORTED: Jenkins restarted during checkout |
| #2 | SCM change | 2.1.2 | SUCCESS, 176 s (first build: base image and pip download) |
| #3 | SCM change (`/health` uptime commit) | 2.1.3 | SUCCESS, 27 s |
| #4 | SCM change (manifest render fix) | 2.1.4 | FAILURE: smoke test hit a draining old pod; rolled back automatically |
| #5 | SCM change (smoke test waits for drain) | 2.1.5 | SUCCESS, 30 s |

![Jenkins stage view](docs/screenshots/q7-job-stages.png)

## 8. Observations

- Layer order matters more than layer count: dependency installs belong before the frequently changing source.
- Containers must not depend on their writable layer for anything that must survive; volumes are the persistence boundary.
- Kubernetes readiness and rolling-update settings are necessary but not sufficient for zero downtime; graceful draining closed the gap.
- A failed release with `maxUnavailable: 0` degrades into a stalled rollout instead of an outage, which makes rollback calm.
- In CD, applying a manifest with a stale image tag and then patching it causes an extra rollout per deploy; render the final manifest once.
- A finished rollout does not mean old pods are gone; a smoke test must wait for the drain, and the automatic rollback proved itself when it did not.
- A self-hosted registry kept the lab independent of Docker Hub limits and credentials, and is the same pattern as a private registry in production.

## 9. Conclusion

The service runs as a non-root, health-checked container, as a Compose stack with persistent state, and as a three-replica Kubernetes Deployment that updates, rolls back and scales without failed requests.
Jenkins deploys every pushed commit to the cluster and verifies the exact version is live.
The full record of commands, logs, screenshots and fixes is in the repository and in the Q8 report.
