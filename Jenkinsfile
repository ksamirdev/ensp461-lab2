// Lab 2 continuous deployment: test, build, push to the lab registry, roll out to Minikube.
pipeline {
    agent any
    options { timestamps(); disableConcurrentBuilds() }
    triggers { pollSCM('H/2 * * * *') }
    environment {
        PUSH_REPO = 'localhost:5001/ensp461-lab2'      // registry as seen from the Docker host
        PULL_REPO = 'lab2-registry:5000/ensp461-lab2'  // same registry as seen from the cluster node
        VERSION = "2.1.${BUILD_NUMBER}"
    }
    stages {
        stage('Test') {
            steps {
                sh '''
                    python3 -m venv .venv
                    .venv/bin/pip install -q -r app/requirements.txt pytest
                    .venv/bin/python -m pytest -q tests
                '''
            }
        }
        stage('Build image') {
            steps {
                sh 'docker build --build-arg APP_VERSION=$VERSION -f docker/Dockerfile -t $PUSH_REPO:$VERSION .'
            }
        }
        stage('Push image') {
            steps {
                sh 'docker push $PUSH_REPO:$VERSION'
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                // Render the new image into the manifest and apply once. Applying k8s/ as-is
                // and then running set image would first roll the pods back to the
                // manifest's tag, creating an extra revision on every deploy.
                sh '''
                    kubectl apply -f k8s/configmap.yaml -f k8s/service.yaml
                    sed "s#image: .*#image: $PULL_REPO:$VERSION#" k8s/deployment.yaml | kubectl apply -f -
                    kubectl annotate deployment/lab2-web kubernetes.io/change-cause="jenkins build $BUILD_NUMBER: $VERSION" --overwrite
                    kubectl rollout status deployment/lab2-web --timeout=180s
                '''
            }
        }
        stage('Smoke test') {
            steps {
                sh '''
                    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
                    BODY=$(curl -fsS http://$NODE_IP:30080/health)
                    echo "$BODY"
                    echo "$BODY" | grep -q "\\"version\\":\\"$VERSION\\""
                '''
            }
        }
    }
    post {
        success { echo "Deployed ensp461-lab2:${VERSION} to Minikube" }
        failure {
            echo 'Deployment failed, rolling back to the previous revision'
            sh 'kubectl rollout undo deployment/lab2-web || true'
        }
    }
}
