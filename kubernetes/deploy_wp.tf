//Declaring Variables
variable "db_host" {}
variable "db_user" {}
variable "db_pass" {}
variable "db_name" {}

//Getting Dependencies
variable "dependencies" {
  type    = "list"
  default = []
}

resource "null_resource" "get_dependency" {
  provisioner "local-exec" {
    command = "echo ${length(var.dependencies)}"
  }
}

//Creating PVC for WordPress Pod
resource "kubernetes_persistent_volume_claim" "wp-pvc" {
  metadata {
    name   = "wp-pvc"
    labels = {
      env     = "Production"
      Country = "India" 
    }
  }

  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
  depends_on = [
    null_resource.get_dependency,
  ]
}

//Creating Deployment for WordPress
resource "kubernetes_deployment" "wp-dep" {
  metadata {
    name   = "wp-dep"
    labels = {
      env     = "Production"
      Country = "India" 
    }
  }
  depends_on = [
    kubernetes_persistent_volume_claim.wp-pvc
  ]

  spec {
    replicas = 1
    selector {
      match_labels = {
        pod     = "wp"
        env     = "Production"
        Country = "India" 
        
      }
    }

    template {
      metadata {
        labels = {
          pod     = "wp"
          env     = "Production"
          Country = "India"  
        }
      }

      spec {
        volume {
          name = "wp-vol"
          persistent_volume_claim { 
            claim_name = kubernetes_persistent_volume_claim.wp-pvc.metadata.0.name
          }
        }

        container {
          image = "wordpress"
          name  = "wp-container"

          env {
            name  = "WORDPRESS_DB_HOST"
            value = var.db_host
          }
          env {
            name  = "WORDPRESS_DB_USER"
            value = var.db_user
          }
          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value = var.db_pass
          }
          env{
            name  = "WORDPRESS_DB_NAME"
            value = var.db_name
          }
          env{
            name  = "WORDPRESS_TABLE_PREFIX"
            value = "wp_"
          }

          volume_mount {
              name       = "wp-vol"
              mount_path = "/var/www/html/"
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

//Creating LoadBalancer Service for WordPress Pods
resource "kubernetes_service" "wpService" {
  metadata {
    name   = "wp-svc"
    labels = {
      env     = "Production"
      Country = "India" 
    }
  }  

  depends_on = [
    kubernetes_deployment.wp-dep
  ]

  spec {
    type     = "NodePort"
    selector = {
      pod = "wp"
    }

    port {
      name = "wp-port"
      port = 80
    }
  }
}

//Output LoadBalancer IP
output "wp_node_port" {
  value = kubernetes_service.wpService.spec.0.port.0.node_port
}
