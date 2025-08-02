job "traefik" {
  datacenters = ["Saliou"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port  "http"{
         static = 80
      }
      port  "admin"{
         static = 8080
      }
    }

    service {
      name = "traefik"
      tags = ["ui", "tools"]
      port = "http"
      provider = "consul"
    }

    task "server" {
      driver = "docker"
      config {
        image = "traefik:2.10.4"
        ports = ["admin", "http"]
        args = [
          "--api.dashboard=true",
          "--api.insecure=true", ### For Test only, please do not use that in production
          "--entrypoints.web.address=:${NOMAD_PORT_http}",
          "--entrypoints.traefik.address=:${NOMAD_PORT_admin}",
          "--providers.nomad=true",
          "--providers.nomad.endpoint.address=http://192.168.13.10:4646" ### IP to your nomad server 
        ]
      }
    }
  }
}
