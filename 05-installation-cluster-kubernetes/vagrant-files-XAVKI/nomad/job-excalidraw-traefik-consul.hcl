job "excalidraw" {
  datacenters = ["Saliou"]
  type = "service"
  group "tools" {
    count = 1

    network {
      port "http" {
        static = 80
      }
    }

    task "excalidraw" {
      driver = "docker"

      config {
        image = "excalidraw/excalidraw:latest"

        ports = [
          "http"
        ]

      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }
      
      service {
				name = "excalidraw"
        tags = [
          "ui",
          "tools",
          "traefik.enable=true",
          "traefik.http.routers.http.rule=Host(`excalidraw.traefik`)",
        ]

        port = "http"

        provider = "consul"

        check {
          type     = "http"
          name     = "app_health"
          path     = "/"
          interval = "20s"
          timeout  = "10s"

          check_restart {
            limit = 3
            grace = "30s"
            ignore_warnings = false
          }
        }
      }
    }
  }
}

