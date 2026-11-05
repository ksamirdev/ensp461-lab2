# ensp461-lab2

ENSP461 - DevOps and Automation, Lab 2: Containerization and Kubernetes Orchestration.

Samir Kumar Gupta, Roll No. 2301730243.

A small Flask service is containerized with Docker, run as a multi-container stack with Docker Compose, deployed to a Minikube Kubernetes cluster, and deployed continuously by a Jenkins pipeline.
All experiments ran on an Ubuntu 24.04.5 LTS OrbStack machine (`ensp461-lab2`, arm64).

## Structure

| Path | Contents |
|---|---|
| `app/` | Flask service (`/`, `/health`, `/visits`) served by gunicorn |
| `tests/` | pytest unit tests |
| `docker/` | `Dockerfile`, `docker-compose.yml` (web + Redis) |
| `k8s/` | ConfigMap, Deployment (rolling update, probes), NodePort Service |
| `Jenkinsfile` | CD pipeline: test, build, push, deploy, smoke test, rollback on failure |
| `jenkins/` | Jenkins init scripts (admin user, SCM-polled job) |
| `scripts/` | one script per question; `rec.sh` records each command with its real output |
| `docs/logs/` | recorded command output for every question |
| `docs/screenshots/` | terminal captures rendered from those logs, and Jenkins and browser screenshots |
| `docs/report-src/` | Markdown source of each report |
| `docs/observations.md` | observations and problems met during the lab |
| `reports/` | final report PDFs, one per question |

## Endpoints

| Path | Response |
|---|---|
| `/` | service name, owner, version, hostname of the container that served it |
| `/health` | `{"status":"UP","version":...}`, used by Docker and Kubernetes probes |
| `/visits` | Redis-backed counter (needs `REDIS_HOST`) |

## Run it

```sh
# unit tests
python3 -m venv .venv && .venv/bin/pip install -r app/requirements.txt pytest && .venv/bin/python -m pytest tests

# single container
docker build -f docker/Dockerfile -t ensp461-lab2:2.0.0 .
docker run -d --name lab2-web -p 5000:5000 ensp461-lab2:2.0.0
curl localhost:5000/health

# web + Redis
docker compose -f docker/docker-compose.yml up -d --build
curl localhost:5000/visits

# local registry and Minikube
docker run -d --name lab2-registry --restart unless-stopped -p 5001:5000 public.ecr.aws/docker/library/registry:2
docker tag ensp461-lab2:2.0.0 localhost:5001/ensp461-lab2:2.0.0 && docker push localhost:5001/ensp461-lab2:2.0.0
minikube start --driver=docker --memory=2048 --cpus=2 --insecure-registry=lab2-registry:5000
docker network connect minikube lab2-registry
kubectl apply -f k8s/
curl http://$(minikube ip):30080/health
```

## Reproduce the recorded runs

Each question has a script that writes its log to `docs/logs/`:

```sh
bash scripts/q0-setup.sh   # toolchain on a fresh Ubuntu 24.04 machine
bash scripts/q1.sh         # ... through q6.sh
bash scripts/q7-setup.sh   # Jenkins wiring for CD
```

Screenshots and PDFs are rebuilt on the Mac host with headless Chrome:

```sh
.venv/bin/pip install markdown
.venv/bin/python scripts/shots.py
.venv/bin/python scripts/build_reports.py
```

## Registry choice

Images are pushed to a self-hosted Distribution registry (`registry:2`) instead of Docker Hub.
The same registry serves the Minikube node, reached as `lab2-registry:5000` on the `minikube` Docker network.
Base images come from `public.ecr.aws/docker/library`, the AWS mirror of Docker Official Images, to avoid Docker Hub's anonymous pull limits.
