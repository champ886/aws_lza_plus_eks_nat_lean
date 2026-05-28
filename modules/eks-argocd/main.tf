# ============================================================================
# ARGOCD MODULE
# Installs ArgoCD via Helm then registers our gitops apps
# ============================================================================

# ─────────────────────────────────────────────────────────────────────────
# Namespace for ArgoCD
# ─────────────────────────────────────────────────────────────────────────
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# ─────────────────────────────────────────────────────────────────────────
# Namespace for our apps
# ─────────────────────────────────────────────────────────────────────────
resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }
}

# ─────────────────────────────────────────────────────────────────────────
# ArgoCD Helm Install
# ─────────────────────────────────────────────────────────────────────────
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "7.4.1"

  # Disable dex (SSO) - not needed for our setup
  set {
    name  = "dex.enabled"
    value = "false"
  }

  # ClusterIP only - access via kubectl port-forward
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Insecure mode - no TLS issues with port-forward
  set {
    name  = "server.insecure"
    value = "true"
  }

  depends_on = [kubernetes_namespace.argocd]
}

# ─────────────────────────────────────────────────────────────────────────
# App Secrets - Created by Terraform BEFORE ArgoCD syncs the apps
# Values come from terraform.tfvars locally or GitHub secrets in CI
# Kubernetes pods reference these by name - nothing sensitive in git
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

  # Must exist before ArgoCD deploys the postgres pod
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

  # Must exist before ArgoCD deploys the pgadmin pod
  depends_on = [kubernetes_namespace.apps]
}

# ─────────────────────────────────────────────────────────────────────────
# ArgoCD App - PostgreSQL
# Tells ArgoCD to deploy postgres from our gitops folder
# Secrets are already in the cluster before this syncs
# ─────────────────────────────────────────────────────────────────────────
resource "kubernetes_manifest" "postgres_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "postgres"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = "main"
        path           = "gitops/apps/postgres"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "apps"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  # ArgoCD must be running AND secrets must exist before syncing
  depends_on = [
    helm_release.argocd,
    kubernetes_secret.postgres,
  ]
}

# ─────────────────────────────────────────────────────────────────────────
# ArgoCD App - pgAdmin
# Tells ArgoCD to deploy pgAdmin from our gitops folder
# ─────────────────────────────────────────────────────────────────────────
resource "kubernetes_manifest" "pgadmin_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "pgadmin"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = "main"
        path           = "gitops/apps/pgadmin"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "apps"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  # Postgres must be registered AND pgadmin secret must exist first
  depends_on = [
    helm_release.argocd,
    kubernetes_manifest.postgres_app,
    kubernetes_secret.pgadmin,
  ]
}
