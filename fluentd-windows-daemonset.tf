resource "kubernetes_service_account" "fluentd-windows" {
  metadata {
    name      = "fluentd"
    namespace = "clu-all"
  }
}

resource "kubernetes_cluster_role" "fluentd-windows" {
  metadata {
    name      = "fluentd"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "fluentd-windows" {
  metadata {
    name = "fluentd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "fluentd"
    namespace = "clu-all"
  }
}

resource "kubernetes_daemonset" "fluentd-windows" {
  metadata {
    name      = "fluentd"
    namespace = "clu-all"
    labels = {
      app     = "fluentd-windows-logging"
      version = "v1"
    }
    annotations = {
      "prometheus.io/port"   = "24231"
      "prometheus.io/scrape" = "true"
      "prometheus.io/path"   = "/metrics"
    }
  }


  spec {

    strategy{
      rolling_update {
        max_unavailable = "1"
      }
    }

    selector {
      match_labels = {
        app     = "fluentd-windows-logging"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = "fluentd-windows-logging"
          version = "v1"
        }
      }
      spec {
        service_account_name            = "fluentd"
        automount_service_account_token = "true"
        container {
          image = "fluentd-windows:v1.9.1"
          name  = "fluentd"
          resources {
            requests {
              cpu    = "100m"
              memory = "200Mi"
            }
            limits {
              memory = "500Mi"
            }
          }
          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
          }
          volume_mount {
            name       = "progdatacontainers"
            mount_path = "/ProgramData/docker/containers"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_HOST"
            value = "elasticsearch-logging"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_PORT"
            value = "9200"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_SCHEME"
            value = "https"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_SSL_VERIFY"
            value = "true"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_SSL_VERSION"
            value = "TLSv1_2"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_USER"
            value = "elastic"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_PASSWORD"
            value = "elastic"
          }
          env {
            name  = "FLUENT_ELASTICSEARCH_PASSWORD"
            value = "fluentd"
          }
        }
        node_selector = {
          "beta.kubernetes.io/os" = "windows"
        }
        termination_grace_period_seconds = "30"
        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }
        volume {
          name = "progdatacontainers"
          host_path {
            path = "/ProgramData/docker/containers"
          }
        }
      }
    }
  }
}
