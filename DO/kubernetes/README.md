### Terraform DigitalOcean Kubernetes Quick Start template
<!-- ![Alt text](./dok8s.svg) -->
<img src="./dok8s.svg" alt="drawing" width="200">

## About this project
This repository contains Terraform configuration for **DigitalOcean Kubernetes service**
This project aims to rapidly deploy the kubernetes service on DigitalOcean cloud with all necessary staff like ingress, cert-manager, CI integration, Network/RBAC policies etc...

## Prerequisites

- Install `terraform`, to get started, visit [terraform.io](https://www.terraform.io/intro/getting-started/install.html).
- Install (Optional) `doctl` [github.com](https://github.com/digitalocean/doctl#macos)
- Install `kubectl` [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- Install (Optional) `helm` [helm.sh](https://github.com/helm/helm#install)

## Getting started

- Create an DigitalOcean API token and place it in `terraform.tfvars` file
- Set token in `terraform.tfvars`  ( *Settings* -> *CI/CD* -> *Runners* -> *Set up a specific Runner manually* ) 
- **Necessarily!** change admin email for LetsEncrypt certificates. Default `admin@example.com`
- Replace DO slugs by actual versions: https://slugs.do-api.dev/
- Replace GitLab RUNNER_NAME value. Default: `client-fra1-kubernetes`
- (Optional) Upload ssh rsa key to DigitalOcean, if you using standalone instance in terraform 

### Environment initialization
Run the *init* command.
```bash
    # The first command only for initializing (only if didn't start before)
    terraform init

```
### Start/change an environment by Terraform
Run the *plan* or *apply* command.
```bash
    # to show changes list
    terraform plan

    # to show and apply the changes
    terraform apply
```
### Change an environment Manually
- (Optional) If you have multiple environments you can add aliases in ~/.bashprofile:

```bash
alias kubectl-cluster-do='export KUBECONFIG=~/.kube/config-cluster-do; export HELM_HOME=~/.helm-cluster-do; export DIGITALOCEAN_CONTEXT=cluster'
```

```bash
    # Authenticate to DO API and provide generated DigitalOcean user token
    doctl auth init
    # Generate kubeconfig
    doctl kubernetes cluster kubeconfig save do-fra1-0
```

### Stopping(destroying) an environment
Run the *destroy* command.

**Warning!!!** the command will not just stop but completely remove the infrastructure used for this environment :

```bash
    # Run the destroy command
    terraform destroy
```
