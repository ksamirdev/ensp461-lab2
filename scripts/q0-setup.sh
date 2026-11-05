# Installs the lab toolchain on a fresh Ubuntu 24.04 machine.
. scripts/rec.sh docs/logs/q0-setup.log
rec "cat /etc/os-release | head -2; uname -m; whoami"
rec "curl -fsSL https://get.docker.com | sudo sh >/dev/null && docker --version"
rec "sudo usermod -aG docker samir && echo added-to-docker-group"
rec "sudo docker compose version; sudo docker buildx version"
rec "curl -fsSLo /tmp/kubectl https://dl.k8s.io/release/\$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl && sudo install /tmp/kubectl /usr/local/bin/kubectl && kubectl version --client"
rec "curl -fsSLo /tmp/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64 && sudo install /tmp/minikube /usr/local/bin/minikube && minikube version --short"
rec "sudo apt-get install -y -qq python3-venv openjdk-21-jdk-headless fontconfig git curl >/dev/null && java -version"
rec "sudo curl -fsSLo /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key && echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list && sudo apt-get update -qq && sudo apt-get install -y -qq jenkins >/dev/null; dpkg -s jenkins | grep -E '^(Package|Version)'; systemctl is-active jenkins"
rec "python3 -m venv .venv && .venv/bin/pip -q install -r app/requirements.txt pytest && .venv/bin/python -m pytest -v tests"
