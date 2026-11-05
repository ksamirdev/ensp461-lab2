. scripts/rec.sh docs/logs/q2-manage.log
R=localhost:5001/ensp461-lab2
rec "docker rm -f lab2-web; docker run -d --name lab2-web -p 5000:5000 ensp461-lab2:2.0.0"
sleep 3
rec "docker ps --filter name=lab2-web --format '{{.Names}} {{.Image}} {{.Status}} {{.Ports}}'"
rec "docker stop lab2-web"
rec "docker inspect lab2-web --format 'exit={{.State.ExitCode}} status={{.State.Status}}'"
rec "docker ps -a --filter name=lab2-web --format '{{.Names}} {{.Status}}'"
rec "docker start lab2-web"
rec "docker ps --filter name=lab2-web --format '{{.Names}} {{.Status}}'"
rec "docker restart lab2-web"
sleep 3
rec "curl -s localhost:5000/health"
rec "docker rm -f lab2-web"
rec "docker ps -a --filter name=lab2-web --format '{{.Names}} {{.Status}}'"
rec "docker rm -f lab2-registry"
rec "docker run -d --name lab2-registry --restart unless-stopped -p 5001:5000 public.ecr.aws/docker/library/registry:2"
sleep 2
rec "docker tag ensp461-lab2:2.0.0 $R:2.0.0"
rec "docker tag ensp461-lab2:2.0.0 $R:latest"
rec "docker images localhost:5001/ensp461-lab2"
rec "docker push --quiet $R:2.0.0"
rec "docker push --quiet $R:latest"
rec "curl -s localhost:5001/v2/ensp461-lab2/tags/list"
rec "docker rmi $R:2.0.0 $R:latest"
rec "docker pull -q $R:2.0.0"
rec "docker compose -f docker/docker-compose.yml --progress quiet up -d --build && echo started"
sleep 5
rec "docker compose -f docker/docker-compose.yml ps"
rec "curl -s localhost:5000/visits"
rec "curl -s localhost:5000/visits"
rec "docker compose -f docker/docker-compose.yml restart web"
sleep 3
rec "curl -s localhost:5000/visits"
rec "docker compose -f docker/docker-compose.yml down"
rec "docker compose -f docker/docker-compose.yml up -d"
sleep 5
rec "curl -s localhost:5000/visits"
rec "docker compose -f docker/docker-compose.yml down -v"
