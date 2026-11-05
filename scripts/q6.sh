. scripts/rec.sh docs/logs/q6-rollout.log
R=localhost:5001/ensp461-lab2; D=deployment/lab2-web; IP=$(minikube ip)
# Polls the service for the whole rollout; any non-200 counts as downtime.
probe() { ok=0; bad=0; while [ ! -f /tmp/stop-probe ]; do c=$(curl -s -m 2 -o /dev/null -w '%{http_code}' http://$IP:30080/health); [ "$c" = 200 ] && ok=$((ok+1)) || bad=$((bad+1)); sleep 0.1; done; echo "probe: $ok ok, $bad failed" | tee -a "$LOG"; rm -f /tmp/stop-probe; }
rec "docker build -q --build-arg APP_VERSION=2.0.1 -f docker/Dockerfile -t $R:2.0.1 . && docker push --quiet $R:2.0.1"
rec "kubectl rollout history $D"
rm -f /tmp/stop-probe; probe & P=$!
rec "kubectl set image $D web=lab2-registry:5000/ensp461-lab2:2.0.1 && kubectl annotate $D kubernetes.io/change-cause='upgrade to 2.0.1' --overwrite"
rec "kubectl rollout status $D --timeout=180s"
touch /tmp/stop-probe; wait $P
rec "kubectl get rs -l app=lab2-web"
rec "curl -s http://$IP:30080/health"
rec "kubectl set image $D web=lab2-registry:5000/ensp461-lab2:9.9.9-missing && kubectl annotate $D kubernetes.io/change-cause='bad image' --overwrite"
rec "kubectl rollout status $D --timeout=30s"
rec "kubectl get pods -l app=lab2-web"
rec "curl -s http://$IP:30080/health"
rec "kubectl rollout history $D"
rm -f /tmp/stop-probe; probe & P=$!
rec "kubectl rollout undo $D --to-revision=1"
rec "kubectl rollout status $D --timeout=180s"
touch /tmp/stop-probe; wait $P
sleep 35
rec "curl -s http://$IP:30080/health"
rec "kubectl scale $D --replicas=6"
rec "kubectl rollout status $D --timeout=120s"
rec "kubectl get deployment lab2-web; kubectl get pods -l app=lab2-web"
rec "kubectl scale $D --replicas=2"
sleep 35
rec "kubectl get deployment lab2-web; kubectl get pods -l app=lab2-web"
rec "kubectl scale $D --replicas=3 && kubectl rollout status $D --timeout=120s"
