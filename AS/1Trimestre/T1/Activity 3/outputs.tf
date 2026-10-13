output "servidores" {
  description = "Lista de nombres de servidores"
  value       = var.servidores
}

output "puertos" {
  description = "Lista de puertos de los servicios"
  value       = var.puertos
}



output "puertos_servicios" {
  description = "Puertos asignados a cada servicio"
  value       = var.puertos_servicios
}

output "entorno" {
  description = "Entornos configurados"
  value       = var.entorno
}



output "servicios" {
  description = "Conjunto de servicios sin duplicados"
  value       = var.servicios
}

output "zonas" {
  description = "Conjunto de zonas disponibles"
  value       = var.zonas
}




output "aplicacion" {
  description = "Configuración de la aplicación"
  value       = var.aplicacion
}




output "servidor_principal" {
  description = "Datos del servidor principal"
  value       = var.servidor_principal
}
