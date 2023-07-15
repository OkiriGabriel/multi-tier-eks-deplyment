helm init --kubeconfig <path_to_kubeconfig_file>
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install my-frontend bitnami/nginx \
  --set image.repository=<frontend_image_repository> \
  --set service.port=<frontend_port> \
  --set ingress.enabled=true \
  --set ingress.hosts[0].name=<frontend_domain> \
  --set ingress.hosts[0].path=<frontend_path> \
  --kubeconfig <path_to_kubeconfig_file>
kubectl get pods --kubeconfig <path_to_kubeconfig_file>
