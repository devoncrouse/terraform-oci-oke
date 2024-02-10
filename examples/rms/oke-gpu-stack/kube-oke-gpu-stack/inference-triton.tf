# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "kubernetes_manifest" "service_triton_nemotron" {
  depends_on = [kubernetes_namespace_v1.inference]
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      labels = {
        app                         = "tritoninferenceserver"
        "app.kubernetes.io/name"    = "tritoninferenceserver"
        "app.kubernetes.io/part-of" = "oke-gpu-stack"
        "app.kubernetes.io/version" = "1"
        version                     = "1"
        release                     = "nemotron"
      }
      name      = "triton-nemotron"
      namespace = local.namespace
    }
    spec = {
      type = "ClusterIP"
      ports = [
        {
          name       = "http-inference-server"
          port       = 8000
          targetPort = "http"
        },
        {
          name       = "grpc-inference-server"
          port       = 8001
          targetPort = "grpc"
        },
        {
          name       = "metrics-inference-server"
          port       = 8002
          targetPort = "metrics"
        },
      ]
      selector = {
        "app.kubernetes.io/name"    = "tritoninferenceserver"
        "app.kubernetes.io/part-of" = "oke-examples"
        release                     = "nemotron"
      }
    }
  }
}

resource "kubernetes_manifest" "deployment_triton_nemotron" {
  depends_on = [kubernetes_namespace_v1.inference]
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "triton-nemotron"
      namespace = local.namespace
      labels = {
        "app"                       = "triton-nemotron"
        "app.kubernetes.io/name"    = "triton-nemotron"
        "app.kubernetes.io/part-of" = "oke-examples"
        "app.kubernetes.io/version" = "1"
        version                     = "1"
        release                     = "nemotron"
      }
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"    = "triton-nemotron"
          "app.kubernetes.io/part-of" = "oke-examples"
          release                     = "nemotron"
        }
      }
      template = {
        metadata = {
          labels = {
            app                         = "triton-nemotron"
            "app.kubernetes.io/name"    = "triton-nemotron"
            "app.kubernetes.io/part-of" = "oke-examples"
            "app.kubernetes.io/version" = "1"
            version                     = "1"
            release                     = "nemotron"
          }
        }
        spec = {
          terminationGracePeriodSeconds = 5
          volumes = [
            { name = "shared", persistentVolumeClaim = { claimName = "oke-fss" } }
          ]
          containers = [
            {
              args            = ["trtserver", "--model-store=/mnt/fss/models"]
              image           = "nvcr.io/nvidia/tensorrtserver:19.09-py3"
              imagePullPolicy = "IfNotPresent"
              livenessProbe = {
                httpGet = {
                  path = "/api/health/live"
                  port = "http"
                }
              }
              name = "tritoninferenceserver"
              ports = [
                { containerPort = 8000, name = "http" },
                { containerPort = 8001, name = "grpc" },
                { containerPort = 8002, name = "metrics" },
              ]
              volumeMounts = [{ name = "shared", mountPath = "/mnt/fss" }]
              readinessProbe = {
                httpGet             = { path = "/api/health/ready", port = "http" }
                initialDelaySeconds = 5
                periodSeconds       = 5
              }
              resources = {
                limits = {
                  "nvidia.com/gpu" = 1
                }
              }
              securityContext = {
                fsGroup   = 1000
                runAsUser = 1000
              }
            },
          ]
        }
      }
    }
  }
}
