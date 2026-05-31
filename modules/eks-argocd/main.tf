# ============================================================================
# ARGOCD MODULE
# ============================================================================

# ─────────────────────────────────────────────────────────────────────────
# Namespaces
# ─────────────────────────────────────────────────────────────────────────
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }
}

# ─────────────────────────────────────────────────────────────────────────
# ArgoCD Helm Install
# wait=true + timeout=600 ensures ALL pods ready and CRDs registered
# ─────────────────────────────────────────────────────────────────────────
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "7.4.1"
  wait       = true
  timeout    = 600

  set {
    name  = "dex.enabled"
    value = "false"
  }

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "server.insecure"
    value = "true"
  }

  depends_on = [kubernetes_namespace.argocd]
}

# ─────────────────────────────────────────────────────────────────────────
# Extra wait after Helm is done
# CRDs are registered during pod startup but may need a moment
# after pods report Ready before they are queryable
# ─────────────────────────────────────────────────────────────────────────
resource "time_sleep" "wait_for_argocd_crds" {
  create_duration = "30s"
  depends_on      = [helm_release.argocd]
}

# ─────────────────────────────────────────────────────────────────────────
# App Secrets
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

# ─────────────────────────────────────────────────────────────────────────
# ArgoCD App - PostgreSQL
# Uses kubectl_manifest instead of kubernetes_manifest
# kubectl_manifest does NOT validate CRDs at plan time - only at apply time
# By apply time ArgoCD is running and CRDs exist
# ─────────────────────────────────────────────────────────────────────────
resource "kubectl_manifest" "postgres_app" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: postgres
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: ${var.git_repo_url}
        targetRevision: main
        path: gitops/apps/postgres
      destination:
        server: https://kubernetes.default.svc
        namespace: apps
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [
    time_sleep.wait_for_argocd_crds,
    kubernetes_secret.postgres,
  ]
}

# ─────────────────────────────────────────────────────────────────────────
# ArgoCD App - pgAdmin
# ─────────────────────────────────────────────────────────────────────────
resource "kubectl_manifest" "pgadmin_app" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: pgadmin
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: ${var.git_repo_url}
        targetRevision: main
        path: gitops/apps/pgadmin
      destination:
        server: https://kubernetes.default.svc
        namespace: apps
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [
    time_sleep.wait_for_argocd_crds,
    kubectl_manifest.postgres_app,
    kubernetes_secret.pgadmin,
  ]
}
