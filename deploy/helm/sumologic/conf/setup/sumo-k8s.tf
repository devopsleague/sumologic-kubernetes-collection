variable "cluster_name" {
  type  = string
  default = "{{ .Values.sumologic.clusterName }}"
}

{{- if .Values.sumologic.collectorName }}
variable "collector_name" {
  type  = string
  default = "{{ .Values.sumologic.collectorName }}"
}
{{- else }}
variable "collector_name" {
  type  = string
  default = "{{ .Values.sumologic.clusterName }}"
}
{{- end }}

variable "namespace_name" {
  type  = string
  default = "{{ .Release.Namespace }}"
}

locals {
  default-metrics-source-name                 = "(default-metrics)"
  apiserver-metrics-source-name               = "apiserver-metrics"
  events-source-name                          = "events"
  kube-controller-manager-metrics-source-name = "kube-controller-manager-metrics"
  kube-scheduler-metrics-source-name          = "kube-scheduler-metrics"
  kube-state-metrics-source-name              = "kube-state-metrics"
  kubelet-metrics-source-name                 = "kubelet-metrics"
  logs-source-name                            = "logs"
  node-exporter-metrics-source-name           = "node-exporter-metrics"
}

provider "sumologic" {}

resource "sumologic_collector" "collector" {
    name  = var.collector_name
    fields  = {
      cluster = var.cluster_name
    }
}

resource "sumologic_http_source" "default_metrics_source" {
    name         = local.default-metrics-source-name
    collector_id = "${sumologic_collector.collector.id}"
}

resource "sumologic_http_source" "apiserver_metrics_source" {
    name         = local.apiserver-metrics-source-name
    collector_id = "${sumologic_collector.collector.id}"
}

resource "sumologic_http_source" "events_source" {
    name         = local.events-source-name
    category     = {{ if .Values.fluentd.events.sourceCategory }}{{ .Values.fluentd.events.sourceCategory | quote }}{{- else}}{{ "\"${var.cluster_name}/${local.events-source-name}\"" }}{{- end}}
    collector_id = "${sumologic_collector.collector.id}"
}

resource "sumologic_http_source" "kube_controller_manager_metrics_source" {
    name         = local.kube-controller-manager-metrics-source-name
    collector_id = "${sumologic_collector.collector.id}"
}

resource "sumologic_http_source" "kube_scheduler_metrics_source" {
    name         = local.kube-scheduler-metrics-source-name
    collector_id = "${sumologic_collector.collector.id}"
}

resource "sumologic_http_source" "kube_state_metrics_source" {
    name         = local.kube-state-metrics-source-name
    collector_id = "${sumologic_collector.collector.id}"
}

resource "sumologic_http_source" "kubelet_metrics_source" {
    name         = local.kubelet-metrics-source-name
    collector_id = "${sumologic_collector.collector.id}"
}

resource "sumologic_http_source" "logs_source" {
    name         = local.logs-source-name
    collector_id = "${sumologic_collector.collector.id}"
}

resource "sumologic_http_source" "node_exporter_metrics_source" {
    name         = local.node-exporter-metrics-source-name
    collector_id = "${sumologic_collector.collector.id}"
}

provider "kubernetes" {
  host                    = "https://kubernetes.default.svc"
  token                   = "${file("/var/run/secrets/kubernetes.io/serviceaccount/token")}"
  cluster_ca_certificate  = "${file("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")}"
}

resource "kubernetes_namespace" "sumologic_collection_namespace" {
  metadata {
    name = var.namespace_name
  }
}

resource "kubernetes_secret" "sumologic_collection_secret" {
  metadata {
    name = "sumologic"
    namespace = var.namespace_name
  }

  data = {
    endpoint-events                           = "${sumologic_http_source.events_source.url}"
    endpoint-logs                             = "${sumologic_http_source.logs_source.url}"
    endpoint-metrics                          = "${sumologic_http_source.default_metrics_source.url}"
    endpoint-metrics-apiserver                = "${sumologic_http_source.apiserver_metrics_source.url}"
    endpoint-metrics-kube-controller-manager  = "${sumologic_http_source.kube_controller_manager_metrics_source.url}"
    endpoint-metrics-kube-scheduler           = "${sumologic_http_source.kube_scheduler_metrics_source.url}"
    endpoint-metrics-kube-state               = "${sumologic_http_source.kube_state_metrics_source.url}"
    endpoint-metrics-kubelet                  = "${sumologic_http_source.kubelet_metrics_source.url}"
    endpoint-metrics-node-exporter            = "${sumologic_http_source.node_exporter_metrics_source.url}"
  }

  type = "Opaque"
}