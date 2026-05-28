# ─────────────────────────────────────────────────────────────────────────
# App Secrets - Created by Terraform (NOT stored in git)
# Values come from GitHub secrets via TF_VAR_ environment variables
# ─────────────────────────────────────────────────────────────────────────
resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  data = {
    POSTGRES_DB       = var.postgres_db
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password
  }

  depends_on = [kubernetes_namespace.apps]
}

resource "kubernetes_secret" "pgadmin" {
  metadata {
    name      = "pgadmin-secret"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  data = {
    PGADMIN_DEFAULT_EMAIL    = var.pgadmin_email
    PGADMIN_DEFAULT_PASSWORD = var.pgadmin_password
  }

  depends_on = [kubernetes_namespace.apps]
}
