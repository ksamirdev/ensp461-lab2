# Second install pass: the first hit download and DNS failures (see q0-setup.log).
. scripts/rec.sh docs/logs/q0-retry.log
A='-o Acquire::Retries=8 -o Acquire::http::Timeout=30'
rec "sudo apt-get update -qq $A && sudo apt-get install -y -qq --fix-missing $A python3-venv openjdk-21-jdk-headless fontconfig >/dev/null && java -version"
rec "sudo curl --retry 8 --retry-all-errors -fsSLo /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key && echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list"
rec "sudo apt-get update -qq $A && sudo apt-get install -y -qq $A jenkins >/dev/null; dpkg -s jenkins | grep -E '^(Package|Version)'; systemctl is-active jenkins"
rec "python3 -m venv .venv && .venv/bin/pip -q install -r app/requirements.txt pytest && .venv/bin/python -m pytest -v tests"
