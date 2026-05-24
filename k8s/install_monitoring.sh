#!/bin/bash
set -e

for cmd in helm terraform; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: '$cmd' is not installed."
    exit 1
  fi
done


echo "Adding Prometheus Community repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "Fetching AWS credentials for Grafana CloudWatch..."
cd terraform
GRAFANA_ACCESS_KEY=$(terraform output -raw grafana_access_key_id)
GRAFANA_SECRET_KEY=$(terraform output -raw grafana_secret_access_key)
cd ..

echo "Deploying kube-prometheus-stack to monitoring namespace..."
export KUBECONFIG=~/.kube/config_vps

helm upgrade --install monitoring-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f k8s/monitoring-values.yaml \
  --set grafana.additionalDataSources[0].name=CloudWatch \
  --set grafana.additionalDataSources[0].type=cloudwatch \
  --set grafana.additionalDataSources[0].jsonData.authType=keys \
  --set grafana.additionalDataSources[0].jsonData.defaultRegion=us-east-1 \
  --set grafana.additionalDataSources[0].secureJsonData.accessKey="$GRAFANA_ACCESS_KEY" \
  --set grafana.additionalDataSources[0].secureJsonData.secretKey="$GRAFANA_SECRET_KEY"

echo "Deployment complete."
echo "Grafana Access: http://<NODE_IP>:32000"
echo "Username: admin"
echo "Password: admin"
