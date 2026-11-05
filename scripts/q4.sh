. scripts/rec.sh docs/logs/q4-network.log
U=public.ecr.aws/docker/library/ubuntu:24.04
rec "docker rm -f n-a n-b n-c; docker network rm lab2-net"
rec "docker network create lab2-net"
rec "docker run -d --name n-a --network lab2-net $U sleep infinity"
rec "docker run -d --name n-b --network lab2-net $U sleep infinity"
rec "docker run -d --name n-c $U sleep infinity"
rec "docker exec n-a sh -c 'apt-get update -qq && apt-get install -y -qq iputils-ping >/dev/null' && echo installed"
rec "docker exec n-c sh -c 'apt-get update -qq && apt-get install -y -qq iputils-ping >/dev/null' && echo installed"
B=$(docker inspect n-b --format '{{.NetworkSettings.Networks.lab2-net.IPAddress}}' 2>/dev/null || true)
[ -n "$B" ] || B=$(docker inspect n-b --format '{{(index .NetworkSettings.Networks "lab2-net").IPAddress}}')
rec "docker inspect n-a n-b --format '{{.Name}} {{(index .NetworkSettings.Networks \"lab2-net\").IPAddress}}'"
rec "docker exec n-a ping -c 2 n-b"
rec "docker exec n-a ping -c 2 $B"
rec "docker exec n-c ping -c 1 -W 2 n-b"
rec "docker exec n-c ping -c 1 -W 2 $B"
rec "docker rm -f n-a n-b n-c; docker network rm lab2-net"
