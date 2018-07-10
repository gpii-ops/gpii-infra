terraform {
  backend "gcs" {}
}

variable "prd_deltas" {
  default = "PT5M PT60M PT24H P7D P52W"
}

variable "stg_deltas" {
  default = "PT15M PT60M PT4H PT24H P7D"
}

variable "dev_deltas" {
  default = "PT5M PT15M PT45M"
}

variable "env" {}
variable "secrets_dir" {}

module "k8s-snapshots" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "k8s-snapshots"
  release_namespace = "kube-system"

  chart_name = "../../../../../charts/k8s-snapshots"
}

resource "null_resource" "enable_backups" {
  depends_on = ["module.k8s-snapshots"]

  provisioner "local-exec" {
    command = <<EOF
      for PV in $(kubectl get pv -o jsonpath="{range .items[*]}{.metadata.name}{' '}"); do
        if [ -z "$(kubectl get pv $PV -o jsonpath="{.metadata.annotations.backup\.kubernetes\.io/deltas}")" ]; then
          kubectl patch pv $PV -p '{"metadata": {"annotations": {"backup.kubernetes.io/deltas": "${
            var.env == "prd" ? "${var.prd_deltas}" : (var.env == "stg" ? "${var.stg_deltas}" : "${var.dev_deltas}")
          }"}}}'
        fi
      done
    EOF
  }
}
