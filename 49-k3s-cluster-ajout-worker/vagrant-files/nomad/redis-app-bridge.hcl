job "app2" {
  datacenters = ["Saliou"]
  type        = "service"

  group "redis" {
    count = 1

    service {
      name     = "redis"
      port     = "redis"
      provider = "nomad"
    }

    network {
      mode = "bridge"
      port "redis" {
        to = 6379
      }
      port "app" {
        to = 8000
        static = 8080
      }
    }

    task "redis" {
      driver = "docker"
      config {
        image = "redis:7"
        ports = ["redis"]
      }

      resources {
        cores  = 1
        memory = 256
      }
    }

    task "app" {
      driver = "docker"
      env {
        REDIS_HOST = "${NOMAD_HOST_IP_redis}"
      }

      config {
        image        = "priximmo/demo_app_redis:v1.0.11"
        ports        = ["app"]
      mount {
        type   = "bind"
        source = "local"
        target = "/etc/app/"
        }
      }

      resources {
        cores  = 1
        memory = 512
      }
      template {
        data        = <<EOH
{{$allocID := env "NOMAD_ALLOC_ID" -}}
{{range nomadService 1 $allocID "redis"}}
redis_host: {{ .Address }}:{{ .Port }}
{{- end}}
redis_password: ubuntu
app_port: 8000
app_listen: "0.0.0.0"
EOH
        destination = "local/config.yaml"
      }
    }

  }
}

