helm init --kubeconfig <path_to_kubeconfig_file>

helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update

helm install my-database bitnami/mysql \
  --set mysqlRootPassword=1234 \
  --set mysqlUser=admin \
  --set mysqlPassword=12345 \
  --set mysqlDatabase=admin \
  --kubeconfig <path_to_kubeconfig_file>

kubectl get pods --kubeconfig <path_to_kubeconfig_file>
