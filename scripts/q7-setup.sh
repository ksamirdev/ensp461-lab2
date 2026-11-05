# Wires the Jenkins service (installed in Q0) to Docker, the registry and the Minikube cluster.
. scripts/rec.sh docs/logs/q7-setup.log
PM=https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.13.2/jenkins-plugin-manager-2.13.2.jar
rec "sudo usermod -aG docker jenkins && id jenkins"
rec "sudo mkdir -p /var/lib/jenkins/.kube && kubectl config view --flatten --minify | sudo tee /var/lib/jenkins/.kube/config >/dev/null && sudo chown -R jenkins: /var/lib/jenkins/.kube && sudo -u jenkins kubectl get nodes"
rec "sudo mkdir -p /etc/systemd/system/jenkins.service.d && printf '[Service]\nEnvironment=\"JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false\"\n' | sudo tee /etc/systemd/system/jenkins.service.d/lab2.conf"
rec "test -s /var/lib/jenkins/admin-password || openssl rand -base64 15 | sudo tee /var/lib/jenkins/admin-password >/dev/null; sudo chown jenkins: /var/lib/jenkins/admin-password; sudo chmod 600 /var/lib/jenkins/admin-password; echo admin password stored in /var/lib/jenkins/admin-password"
rec "sudo install -d -o jenkins -g jenkins /var/lib/jenkins/init.groovy.d && sudo install -o jenkins -g jenkins -m 644 jenkins/security.groovy jenkins/job.groovy /var/lib/jenkins/init.groovy.d/ && ls /var/lib/jenkins/init.groovy.d"
rec "curl -fsSL --retry 5 -o /tmp/jpm.jar $PM && sudo -u jenkins java -jar /tmp/jpm.jar --war /usr/share/java/jenkins.war -d /var/lib/jenkins/plugins --plugins workflow-aggregator git pipeline-stage-view timestamper 2>&1 | tail -3"
rec "sudo systemctl daemon-reload && sudo systemctl restart jenkins && for i in \$(seq 60); do curl -fs -o /dev/null localhost:8080/login && break; sleep 3; done; systemctl is-active jenkins"
rec "curl -s localhost:8080/api/json?tree=jobs[name,url] ; echo"
rec "curl -sI localhost:8080/ | grep -i -E '^(HTTP|X-Jenkins:)'"
