# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}
variable "gitlab_runner_token" {}
variable "grafana_admin_pass" {}
variable "slack_api_url" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

### Example Droplet:
// # Create a web server
// resource "digitalocean_droplet" "test1" {
//   image  = "ubuntu-18-04-x64"
//   name   = "test-1"
//   region = "fra1"
//   size   = "s-1vcpu-1gb"
//   ssh_keys = ["a5:c8:f7:da:13:34:28:a5:be:5d:7e:ff:35:11:e5:dd"]
//   tags    = ["terraform-managed"]
// }

// output "ip" {
//   value = digitalocean_droplet.test1.ipv4_address
// }


### Kubernetes: ###
resource "digitalocean_kubernetes_cluster" "cluster0" {
  name    = "do-fra1-0"
  region  = "fra1"
  // Get actual version: https://slugs.do-api.dev/
  version = "1.15.3-do.2"
  tags    = ["terraform-managed"]
  node_pool {
    name       = "staging"
    size       = "s-1vcpu-2gb"
    node_count = 1
    tags    = ["terraform-managed"]
  }
}
resource "digitalocean_kubernetes_node_pool" "production" {
  cluster_id = "${digitalocean_kubernetes_cluster.cluster0.id}"
  name       = "production"
  // Uncomment for demo/test:
  size       = "s-1vcpu-2gb"
  // Uncomment for production CPU Optimized: 4GB/2vCPU/40$
  // size       = "c-2" 
  node_count = 1
  tags    = ["terraform-managed"]
}

provider "kubernetes" {
  host = "${digitalocean_kubernetes_cluster.cluster0.endpoint}"
  client_certificate     = "${base64decode(digitalocean_kubernetes_cluster.cluster0.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(digitalocean_kubernetes_cluster.cluster0.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(digitalocean_kubernetes_cluster.cluster0.kube_config.0.cluster_ca_certificate)}"
}

# Add namespaces
resource "kubernetes_namespace" "ingress_production" {
  metadata {
    name = "ingress-production"
  }
}
resource "kubernetes_namespace" "ingress_staging" {
  metadata {
    name = "ingress-staging"
  }
}
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
  }
}
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      "certmanager.k8s.io/disable-validation" = "true"
    }
  } 
}

# Store kubeconfig in file for CRD.  // Will be regenerated each time terraform apply
resource "local_file" "kubernetes_config" {
  sensitive_content  = "${digitalocean_kubernetes_cluster.cluster0.kube_config.0.raw_config}"
  filename = ".kubeconfig.yaml"
}

# Add storageclass with retain properties
resource "kubernetes_storage_class" "do_block_storage_retain" {
  metadata {
    name = "do-block-storage-retain"
  }
  storage_provisioner = "dobs.csi.digitalocean.com"
  reclaim_policy      = "Retain"
}

# GitLab integration 
resource "kubernetes_service_account" "gitlab_admin" {
  metadata {
    name      = "gitlab-admin"
    namespace = "kube-system"
  }
}
resource "kubernetes_cluster_role_binding" "gitlab_admin" {
  metadata {
    name = "gitlab-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "gitlab-admin"
    namespace = "kube-system"
  }
}
data "external" "gitlab_sa_token" {
  depends_on = ["kubernetes_service_account.gitlab_admin"]
  program = ["bash", "${path.root}/get_token.sh"]
}

// Output for GitLab integration:
output "kubernetes_api_url" {
  value = "${digitalocean_kubernetes_cluster.cluster0.endpoint}"
}
output "kubernetes_ca_certificate" {
  value = "${base64decode(digitalocean_kubernetes_cluster.cluster0.kube_config.0.cluster_ca_certificate)}"
}
output "gitlab_sa_token" {
  value = "${data.external.gitlab_sa_token.result.token}"
}


## Helm Tiller SA ##
provider "helm" {
  kubernetes {
    host = "${digitalocean_kubernetes_cluster.cluster0.endpoint}"
    client_certificate     = "${base64decode(digitalocean_kubernetes_cluster.cluster0.kube_config.0.client_certificate)}"
    client_key             = "${base64decode(digitalocean_kubernetes_cluster.cluster0.kube_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(digitalocean_kubernetes_cluster.cluster0.kube_config.0.cluster_ca_certificate)}"
  }
  install_tiller = "true"
  service_account = "tiller"
}
resource "kubernetes_service_account" "helm" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}
resource "kubernetes_cluster_role_binding" "helm" {
  metadata {
    name = "tiller"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }
}

## Helm releses: ##
// HELM | Ingress for production:
resource "helm_release" "ingress_production" {
  depends_on = [
    "kubernetes_service_account.helm",
    "kubernetes_cluster_role_binding.helm"
  ]
  name      = "ingress-production"
  namespace = "ingress-production"
  chart     = "stable/nginx-ingress"
  version   = "1.11.5"
  timeout   = "600"
  // values = [
  //   "${file("values.yaml")}"
  // ]
  # OR
    values    = [
      <<-EOF
controller:
  replicaCount: 2
  affinity:
    # An example of preferred pod anti-affinity, weight is in the range 1-100
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - nginx-ingress
          topologyKey: kubernetes.io/hostname
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
defaultBackend:
  affinity: {}
  nodeSelector:
    doks.digitalocean.com/node-pool: production
  resources:
    requests:
      cpu: 10m
      memory: 20Mi
       EOF
    ]
  set {
    name  = "controller.ingressClass"
    value = "ingress-production"
  }
}

// HELM | Ingress for staging:
resource "helm_release" "ingress_staging" {
  depends_on = [
    "kubernetes_service_account.helm",
    "kubernetes_cluster_role_binding.helm"
  ]
  name      = "ingress-staging"
  namespace = "ingress-staging"
  chart     = "stable/nginx-ingress"
  version   = "1.11.5"
  timeout   = "600"
  // values = [
  //   "${file("values.yaml")}"
  // ]
  # OR
    values    = [
      <<-EOF
controller:
  replicaCount: 2
  affinity:
    # An example of preferred pod anti-affinity, weight is in the range 1-100
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - nginx-ingress
          topologyKey: kubernetes.io/hostname
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
defaultBackend:
  affinity: {}
  nodeSelector:
    doks.digitalocean.com/node-pool: staging
  resources:
    requests:
      cpu: 10m
      memory: 20Mi
       EOF
    ]
  set {
    name  = "controller.ingressClass"
    value = "ingress-staging"
  }
}

// HELM | GitLab Runner:
data "helm_repository" "gitlab" {
    name = "gitlab"
    url  = "https://charts.gitlab.io"
}
resource "helm_release" "gitlab_runner" {
  depends_on = [
    "kubernetes_service_account.helm",
    "kubernetes_cluster_role_binding.helm"
  ]
  name      = "gitlab-runner"
  namespace = "gitlab"
  chart     = "gitlab/gitlab-runner"
  timeout   = "300"
  // values = [
  //   "${file("values.yaml")}"
  // ]
  # OR
    values    = [
      <<-EOF
gitlabUrl: https://gitlab.com/
envVars:
  - name: RUNNER_NAME
    value: client-fra1-kubernetes
concurrent: 2
checkInterval: 0
## ref: https://docs.gitlab.com/runner/monitoring/#configuration-of-the-metrics-http-server
# metrics:
#   enabled: true
rbac:
  create: true
  clusterWideAccess: true
# nodeSelector:
#   # nodegroup: staging
#   doks.digitalocean.com/node-pool: "staging"
runners:
  image: ubuntu:18.04
  tags: "kubernetes,privileged,dind"
  runUntagged: true
  privileged: true
  namespace: gitlab
  builds:
    cpuRequests: 100m
    memoryRequests: 128Mi
  services:
    cpuRequests: 100m
    memoryRequests: 128Mi
  helpers:
    cpuRequests: 100m
    memoryRequests: 128Mi
  # nodeSelector:
  #   # nodegroup: staging
  #   doks.digitalocean.com/node-pool: staging
  env:
    DOCKER_TLS_CERTDIR: ""
       EOF
    ]
  set {
    name  = "runnerRegistrationToken"
    value = "${var.gitlab_runner_token}"
  }
}

// HELM | Cert-manager
data "helm_repository" "jetstack" {
    name = "jetstack"
    url  = "https://charts.jetstack.io"
}
resource "helm_release" "cert_manager" {
  keyring = ""
  repository = "${data.helm_repository.jetstack.metadata.0.name}"
  name = "cert-manager"
  chart = "jetstack/cert-manager"
  namespace = "cert-manager"
  version    = "v0.10.0"
  depends_on = [
    "helm_release.ingress_production",
    "local_file.kubernetes_config"
  ]
  set {
    name  = "webhook.enabled"
    // Disable this for AWS
    value = "true" 
  }
  provisioner "local-exec" {
    command = "kubectl --kubeconfig=.kubeconfig.yaml create -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.10/deploy/manifests/00-crds.yaml || true"
  }
  provisioner "local-exec" {
    command = <<EOT
cat <<EOF | kubectl --kubeconfig=.kubeconfig.yaml apply -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging-http
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: admin@example.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: le-staging-http-secret
    # Enable the HTTP-01 challenge provider
    http01: {}
    # http01:
    #   ingressClass: nginx
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod-http
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: admin@example.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: le-prod-http-secret
    # Enable the HTTP-01 challenge provider
    http01: {}
    # http01:
    #   ingressClass: nginx
EOF
EOT
  }
}

// resource "helm_release" "prometheus_operator" {
//   depends_on = [
//     "kubernetes_service_account.helm",
//     "kubernetes_cluster_role_binding.helm"
//   ]
//   name      = "prometheus-operator"
//   namespace = "monitoring"
//   chart     = "stable/prometheus-operator"
//   timeout   = "300"
//   values = [
//     "${file("./helm-values/helm-prometheus-operator-values.yaml")}"
//   ]
//   set {
//     name  = "grafana.adminPassword"
//     value = "${var.grafana_admin_pass}"
//   }
//   set {
//     name  = "alertmanager.config.global.slack_api_url"
//     value = "${var.slack_api_url}"
//   }
// }

resource "helm_release" "kube_state_metrics" {
  depends_on = [
    "kubernetes_service_account.helm",
    "kubernetes_cluster_role_binding.helm"
  ]
  name      = "kube-state-metrics"
  namespace = "kube-system"
  chart     = "stable/kube-state-metrics"
  timeout   = "300"
  // values = [
  //   "${file("./helm-values/helm-kube-state-metrics-values.yaml")}"
  // ]
}

