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
          "--providers.consulcatalog=true",
          "--providers.consulcatalog.watch=true",
          "--providers.consulcatalog.endpoint.datacenter=Saliou",
          "--providers.consulcatalog.cache=true",
          "--providers.consulcatalog.exposedByDefault=false",
          "--providers.consulcatalog.endpoint.address=consul.service.Saliou.Saliou:8500"
        ]
      }
    }
  }
}
