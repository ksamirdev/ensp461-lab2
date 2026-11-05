# Lab 2 observations

Samir Kumar Gupta, Roll No. 2301730243.
Machine: Ubuntu 24.04.5 LTS OrbStack VM `ensp461-lab2` (arm64) on a Mac, 5 to 6 November 2026.

## Findings per experiment

### Q1 - image and container

- The image has 9 filesystem layers: 4 from `python:3.12-slim` and 5 from the Dockerfile.
  `ENV`, `EXPOSE`, `USER`, `HEALTHCHECK` and `CMD` only add metadata (0 B entries in `docker history`).
- The app adds about 20 MB to a 227 MB image, almost all of it the pip install layer.
- `touch app/app.py` did not invalidate the cache.
  BuildKit keys `COPY` on file contents, not modification time.
- The container ran as uid 10001 and became `healthy` once the `HEALTHCHECK` passed.

### Q2 - lifecycle, registry, Compose

- `docker stop` ended gunicorn cleanly (exit code 0); the stopped container stayed listed until `docker rm`.
- Two tags of one image share one image ID; `docker rmi` of a tag only untags.
- The Compose visit counter reached 4 across a web restart and a full `down`/`up`, because Redis data sits in a named volume.
  Only `down -v` removed it.
- `depends_on` with `condition: service_healthy` held the web container until Redis answered `PING`.

### Q3 - storage

- Data in the container writable layer vanished with the container.
- A named volume kept data across containers; a bind mount showed host and container edits on both sides.

### Q4 - networking

- Containers on the user-defined network `lab2-net` reached each other by name (embedded DNS) and by IP.
- A container on the default bridge could not resolve `n-b` and could not reach its IP: the networks are isolated.

### Q5 - Kubernetes deployment

- The Minikube node pulled images from the lab registry over the `minikube` Docker network, as a real cluster pulls from a registry.
- Requests to one NodePort were answered by different pods.
- The first `curl` right after `rollout status` returned nothing; kube-proxy had not yet programmed the NodePort.

### Q6 - rollouts and scaling

- Without a `preStop` hook, a rolling update lost 5 of 34 probe requests and a rollback 2 of 82, despite `maxUnavailable: 0`.
  Pods stopped serving before kube-proxy removed them from the Service.
- With `preStop: sleep 5`, the same operations lost 0 of 61 and 0 of 30.
- A missing image tag stalled the rollout in `ErrImagePull` without an outage; the three previous pods kept serving.
- `rollout undo` reused the original ReplicaSet; scaling changed replica counts without new revisions.

### Q7 - continuous deployment

- Builds 2 to 5 were started by SCM polling after `git push`, with no manual trigger.
- Every build deployed a unique version `2.1.<build>` and the smoke test checked that exact version was live.
- `kubectl apply -f k8s/` followed by `kubectl set image` first reset the pods to the manifest's `2.0.0`, creating two revisions per deploy.
  The pipeline now renders the build's image into the manifest and applies it once.
- Build 4 failed its smoke test: `rollout status` returned while old pods were still draining, and the first check reached a 2.1.3 pod.
  The `post` failure step rolled the cluster back automatically.
  The smoke test now requires five consecutive new-version answers; build 5 passed.

## Problems met and fixes

| Problem | Cause | Fix |
|---|---|---|
| `docker pull` failed on the Mac: `unauthorized: incorrect username or password` | stale Docker Hub login in the Mac keychain | base images from `public.ecr.aws/docker/library`, a self-hosted registry, and later a clean VM |
| Bind mount write failed: `Operation not permitted` | macOS privacy controls on `~/Desktop` | moved the lab into a dedicated Ubuntu 24.04 OrbStack machine |
| JDK download timed out; `pkg.jenkins.io` not resolved | unstable network during install | second install pass with apt retries (`q0-retry.log`) |
| `minikube start` stuck at 80% of `kicbase` | gcr.io download stalled at a few bytes/s | pulled `kicbase/stable` from Docker Hub with `--base-image`, then switched to a faster network |
| Q2 lifecycle steps found no container | the script relied on the container left by Q1 | Q2 now starts its own container |
| Jenkins init script did not create the user | the setup wizard had already created a security realm on first boot | made `security.groovy` idempotent |
| Build 1 aborted during checkout | Jenkins was restarted by the setup script while the build was cloning | aborted it; builds 2 to 4 ran cleanly |
| Jenkins job list printed empty | `curl` treated `[]` in the query as a glob | `curl -g` |
| `minikube kubectl` hung | it downloads its own kubectl binary | used the installed `kubectl` |
