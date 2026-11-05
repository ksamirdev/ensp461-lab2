# usage: bash scripts/q7-build.sh <build-number>
# Waits for a Jenkins build of ensp461-lab2-cd to finish and records its evidence.
N=$1; J=localhost:8080/job/ensp461-lab2-cd
. scripts/rec.sh docs/logs/q7-build$N.log
until curl -sf "$J/$N/api/json" | grep -q '"building":false'; do sleep 5; done
rec "curl -s '$J/$N/api/json' | python3 -c 'import json,sys; b=json.load(sys.stdin); print(\"build\", b[\"number\"], b[\"result\"], str(b[\"duration\"]//1000)+\"s\", [c.get(\"shortDescription\") for a in b[\"actions\"] for c in a.get(\"causes\", [])])'"
rec "curl -s '$J/$N/consoleText' | grep -v -E '^\s+at |Counting objects|Compressing objects|Receiving objects|Resolving deltas|^#[0-9]+ (sha256|extracting|transferring)'"
rec "kubectl rollout history deployment/lab2-web"
rec "kubectl get deployment lab2-web -o wide"
rec "kubectl get pods -l app=lab2-web"
rec "curl -s http://\$(minikube ip):30080/health"
rec "curl -s localhost:5001/v2/ensp461-lab2/tags/list"
