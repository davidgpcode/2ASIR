variable "servidores" {
  description = "Nombres de los servidores"
  type        = list(string)
  default     = ["web", "dns", "base-datos"]
}

variable "puertos" {
  description = "Puertos de los servicios"
  type        = list(number)
  default     = [80, 443, 53]
}



variable "puertos_servicios" {
  description = "Mapa de servicios y sus puertos"
  type        = map(number)
  default = {
    web        = 80
    https      = 443
    dns        = 53
    base_datos = 3306
  }
}

variable "entorno" {
  description = "Puertos configurados para cada entorno"
  type        = map(string)
  default = {
    desarrollo = "dev"
    pruebas    = "test"
    produccion = "prod"
  }
}



variable "servicios" {
  description = "Conjunto de servicios disponibles"
  type        = set(string)
  default     = ["web", "dns", "web", "correo"]
}

variable "zonas" {
  description = "Zonas disponibles para los servidores"
  type        = set(string)
  default     = ["norte", "sur", "norte"]
}



variable "aplicacion" {
  description = "Configuración de la aplicación"
  type = object({
    nombre     = string
    entorno    = string
    puerto     = number
    replicas   = number
  })
  default = {
    nombre   = "tienda-online"
    entorno  = "produccion"
    puerto   = 8080
    replicas = 3
  }
}



variable "servidor_principal" {
  description = "Datos del servidor principal"
  type        = tuple([string, string, number, bool])
  default     = ["web-01", "192.168.1.10", 22, false]
}
