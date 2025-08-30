
locals {
  bucket_name = "${profile}+ ${bucket_name}"
}


module "bucket_crateion" {

  source             = "../../../modules/fod_profile_bucket"
  bucket_name        = local.bucket_name
  cluster_oidc_url   = var.cluster_oidc_url
  irsa_role_name     = var.irsa_role_name
  bucket_policy_name = var.bucket_policy_name

}

# MySQL Release
resource "helm_release" "mysql" {
  name             = "mysql"
  namespace        = "food-ordering"
  create_namespace = true

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"
  version    = "9.12.0"

  values = [file("${path.module}/helm/mysql-values.yaml")]
}

# Redis Release
resource "helm_release" "redis" {
  name      = "redis"
  namespace = helm_release.mysql.namespace

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "18.8.2"

  values = [file("${path.module}/helm/redis-values.yaml")]

}

# Spring Boot Release (local chart)
resource "helm_release" "springboot_app" {
  name      = "springboot-app"
  namespace = helm_release.mysql.namespace

  chart = "${path.module}/../charts"

  values = [
    file("${path.module}/helm/springboot-app-values.yaml")
  ]
}








