. scripts/rec.sh docs/logs/q1-build-run.log
rec "docker build -f docker/Dockerfile -t ensp461-lab2:2.0.0 . --progress=plain"
rec "docker images ensp461-lab2"
rec "docker history --format 'table {{.CreatedBy}}\t{{.Size}}' --no-trunc=false ensp461-lab2:2.0.0"
rec "docker image inspect ensp461-lab2:2.0.0 --format '{{len .RootFS.Layers}} layers'"
rec "docker rm -f lab2-web"
rec "docker run -d --name lab2-web -p 5000:5000 ensp461-lab2:2.0.0"
sleep 3
rec "docker ps --filter name=lab2-web"
rec "curl -s localhost:5000/"
rec "curl -s localhost:5000/health"
rec "docker exec lab2-web id"
rec "docker top lab2-web"
rec "docker logs lab2-web"
sleep 18
rec "docker inspect lab2-web --format 'health={{.State.Health.Status}}'"
rec "touch app/app.py && docker build -f docker/Dockerfile -t ensp461-lab2:2.0.0 . --progress=plain 2>&1 | grep -E 'CACHED|DONE' | head -12"
