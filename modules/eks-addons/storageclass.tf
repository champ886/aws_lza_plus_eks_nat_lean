resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = {
    type = "gp3"
  }

  volume_binding_mode = "WaitForFirstConsumer"

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}