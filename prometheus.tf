# Wait for Kubernetes to be ready before proceeding
resource "time_sleep" "wait_for_kubernetes" {
    depends_on = [
        module.eks
    ]
    create_duration = "20s" # Wait for 20 seconds
}

# Define a Kubernetes namespace named "prometheus"
resource "kubernetes_namespace" "kube-namespace" {
    depends_on = [time_sleep.wait_for_kubernetes] # Ensure Kubernetes is ready before creating namespace
    metadata {
        name = "prometheus" # Name the namespace "prometheus"
    }
}

# Install Prometheus using Helm in the "prometheus" namespace
resource "helm_release" "prometheus" {
    depends_on = [kubernetes_namespace.kube-namespace, time_sleep.wait_for_kubernetes] # Ensure namespace and Kubernetes are ready
    name       = "prometheus" # Name the Helm release "prometheus"
    repository = "https://prometheus-community.github.io/helm-charts" # Use this repository to fetch Helm charts
    chart      = "kube-prometheus-stack" # Use the "kube-prometheus-stack" chart
    namespace  = kubernetes_namespace.kube-namespace.id # Install in the "prometheus" namespace
    create_namespace = true # Create the namespace if it doesn't exist
    version    = "51.3.0" # Use version 51.3.0 of the Helm chart
    values = [
        file("values.yaml") # Provide values from a file named "values.yaml"
    ]
    timeout = 2000 # Set a timeout of 2000 seconds for the Helm release

    # Set specific values in the Helm chart's configuration
    set {
        name  = "podSecurityPolicy.enabled" # Enable the PodSecurityPolicy
        value = true
    }

    set {
        name  = "server.persistentVolume.enabled" # Disable the persistent volume
        value = false
    }

    # Specify resource requests and limits for the Prometheus server
    set {
        name = "server\\.resources" # Specify server resources
        value = yamlencode({
            limits = {
                cpu    = "200m" # Set CPU limit to 200m
                memory = "50Mi" # Set memory limit to 50Mi
            }
            requests = {
                cpu    = "100m" # Set CPU request to 100m
                memory = "30Mi" # Set memory request to 30Mi
            }
        })
    }
}
