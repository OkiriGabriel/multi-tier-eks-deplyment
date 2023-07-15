# Multi-Tier Application Deployment in EKS

This repository contains Terraform scripts and Helm charts to deploy a multi-tier application on AWS EKS. The application consists of an application tier and a database tier, with network policies implemented to restrict traffic flow between layers.

## Architecture

The architecture of the application deployment is as follows:

- EKS Cluster: A managed Kubernetes cluster to host the application and database.
- Application Tier: An application deployed using Helm, running in the application tier.
- Database Tier: A database deployed using Helm, running in the database tier.
- Network Policies: Security groups and network ACLs are used to restrict traffic between the application and database tiers.

## Deployment Steps

To deploy the multi-tier application, follow these steps:

1. Clone this repository.
2. Modify the Terraform script (`main.tf`) to customize the deployment (e.g., region, VPC settings, security group rules, Helm chart versions).
3. Modify the Helm values files (`helm/my-app-values.yaml`, `helm/my-database-values.yaml`) to configure application and database-specific settings.
4. Run `terraform init` to initialize the Terraform workspace.
5. Run `terraform apply` to provision the EKS cluster and related resources.
6. Change to the application Helm chart directory (`my-app-chart`).
7. Run `helm install my-app .` to deploy the application.
8. Change to the database Helm chart directory (`my-database-chart`).
9. Run `helm install my-database .` to deploy the database.

## Implemented Network Policies

The following network policies are implemented to restrict traffic flow between the application and database tiers:

- Inbound Rules:
  - Application Tier Security Group: Allows inbound traffic on port 80 (HTTP) from any source.
  - Database Tier Security Group: Allows inbound traffic on port 3306 (MySQL) from any source.

- Outbound Rules:
  - Application Tier Security Group: Allows outbound traffic to any destination on any port.
  - Database Tier Security Group: Allows outbound traffic to any destination on any port.

Please note that you may need to modify these network policies based on your specific requirements.

