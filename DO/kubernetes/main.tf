# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}
variable "do_kubernetes_slug" {}
variable "do_node_pool_staging_droplet_slug" {}
variable "do_node_pool_production_droplet_slug" {}
variable "gitlab_runner_token" {}
variable "grafana_admin_pass" {}
variable "slack_api_url" {}
variable "slack_channel_name" {}

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
  version = "${var.do_kubernetes_slug}"
  tags    = ["terraform-managed"]
  node_pool {
    name       = "staging"
    size       = "${var.do_node_pool_staging_droplet_slug}"
    node_count = 1
    tags    = ["terraform-managed"]
  }
}
resource "digitalocean_kubernetes_node_pool" "production" {
  cluster_id = "${digitalocean_kubernetes_cluster.cluster0.id}"
  name       = "production"
  size       = "${var.do_node_pool_production_droplet_slug}"
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
      cpu: 50m
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
      cpu: 50m
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
  version    = "v0.10.1"
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
    // This step has issues, so you may need to apply ClusterIssuers manually :-\
    command = "kubectl --kubeconfig=.kubeconfig.yaml create -f ./kube/kube-clusterIssuers.yaml || true"
  }
}

// HELM | kube-state-metrics (DO monitoring)
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
  //   "${file("./helm/helm-kube-state-metrics-values.yaml")}"
  // ]
}

// HELM | metrics-server (kubectl top, etc..)
resource "helm_release" "metrics_server" {
  depends_on = [
    "kubernetes_service_account.helm",
    "kubernetes_cluster_role_binding.helm"
  ]
  name      = "metrics-server"
  namespace = "kube-system"
  chart     = "stable/metrics-server"
  timeout   = "300"
  values    = [
    <<-EOF
args:
  - --kubelet-preferred-address-types=InternalIP
  EOF
  ]
}

// HELM | prometheus-operator
resource "helm_release" "prometheus_operator" {
  depends_on = [
    "kubernetes_service_account.helm",
    "kubernetes_cluster_role_binding.helm"
  ]
  name      = "prometheus-operator"
  namespace = "monitoring"
  chart     = "stable/prometheus-operator"
  timeout   = "300"
  recreate_pods = "true"
  values = [
    "${file("./helm/helm-prometheus-operator-values.yaml")}"
  ]
  set {
    name  = "grafana.adminPassword"
    value = "${var.grafana_admin_pass}"
  }
  set {
    name  = "alertmanager.config.global.slack_api_url"
    value = "${var.slack_api_url}"
  }
  set {
    name  = "alertmanager.config.receivers[0].slack_configs[0].channel"
    value = "${var.slack_channel_name}"
  }
}

// HELM | loki-stack
data "helm_repository" "loki" {
    name = "loki"
    url  = "https://grafana.github.io/loki/charts"
}
resource "helm_release" "loki_stack" {
  depends_on = [
    "kubernetes_service_account.helm",
    "kubernetes_cluster_role_binding.helm"
  ]
  name      = "loki-stack"
  namespace = "monitoring"
  chart     = "loki/loki-stack"
  timeout   = "300"
  // values = [
  //   "${file("./helm/helm-loki-stack-values.yaml")}"
  // ]
  values    = [
    <<-EOF
loki:
  persistence:
    enabled: true
    accessModes:
    - ReadWriteOnce
    size: 10Gi
    annotations: {}
    storageClassName: do-block-storage
  EOF
  ]
}
