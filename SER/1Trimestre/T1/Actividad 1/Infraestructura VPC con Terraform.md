# Infraestructura Base AWS con Terraform


### 1. Archivo variables.tf

    david@davidg:~/terraform-vpc$ cat -n variables.tf
        1	variable "nombre" {
        2	  description = "Mi nombre, para etiquetar los recursos"
        3	  type        = string
        4	  default     = "david"
        5	}
    david@davidg:~/terraform-vpc$ 

**variable "nombre"**: es una variable donde guardo mi nombre. Los recursos la utilizan para ponerlo en sus etiquetas (ejemplo: *vpc-david*).

---

### 2. Archivo vpc.tf

    david@davidg:~/terraform-vpc$ cat -n vpc.tf
        1	provider "aws" {
        2	  region = "us-east-1"
        3	}
        4	
        5	resource "aws_vpc" "main_vpc" {
        6	  cidr_block           = "10.100.0.0/16"
        7	  enable_dns_support   = true
        8	  enable_dns_hostnames = true
        9	
        10	  tags = { Name = "vpc-${var.nombre}" }
        11	}
        12	
        13	resource "aws_internet_gateway" "igw" {
        14	  vpc_id = aws_vpc.main_vpc.id
        15	
        16	  tags = { Name = "igw-${var.nombre}" }
        17	}
    david@davidg:~/terraform-vpc$ 

**provider "aws"**: le dice a Terraform que trabaje con AWS, en la región **us-east-1**, que es la permitida por AWS Academy.
  
**aws_vpc.main_vpc**: es la red privada dentro de AWS. Con **10.100.0.0/16** tiene 2^16 (65536) direcciones IP. Las opciones *enable_dns_support* y *enable_dns_hostnames* permiten que las máquinas de la red se encuentren por nombre y no solo por IP.

**aws_internet_gateway.igw**: es la puerta de enlace de la red hacia Internet.

---

### 3. Archivo subred_publica.tf

    david@davidg:~/terraform-vpc$ cat -n subred_publica.tf
        1	resource "aws_subnet" "subred_publica" {
        2	  vpc_id                  = aws_vpc.main_vpc.id
        3	  cidr_block              = "10.100.1.0/24"
        4	  map_public_ip_on_launch = true
        5	  availability_zone       = "us-east-1a"
        6	
        7	  tags = { Name = "subred-publica-${var.nombre}" }
        8	}
        9	
        10	resource "aws_route_table" "public_rt" {
        11	  vpc_id = aws_vpc.main_vpc.id
        12	
        13	  route {
        14	    cidr_block = "0.0.0.0/0"
        15	    gateway_id = aws_internet_gateway.igw.id
        16	  }
        17	
        18	  tags = { Name = "rt-publica-${var.nombre}" }
        19	}
        20	
        21	resource "aws_route_table_association" "public_rta" {
        22	  subnet_id      = aws_subnet.subred_publica.id
        23	  route_table_id = aws_route_table.public_rt.id
        24	}
    david@davidg:~/terraform-vpc$ 

**aws_subnet.subred_publica**: es una parte más pequeña de la VPC, con 256 IPs (/24). Como tiene *map_public_ip_on_launch = true*, cada servidor que se cree aquí recibe una IP pública y se puede acceder a él desde Internet.

**aws_route_table.public_rt**: es una tabla de rutas que indica que todo el tráfico hacia Internet *0.0.0.0/0* sale por el Internet Gateway.

**aws_route_table_association**: conecta la tabla de rutas con la subred. Por eso la subred es pública.

---

### 4. Archivo subred_privada.tf

    david@davidg:~/terraform-vpc$ cat -n subred_privada.tf
        1	resource "aws_subnet" "subred_privada" {
        2	  vpc_id            = aws_vpc.main_vpc.id
        3	  cidr_block        = "10.100.2.0/24"
        4	  availability_zone = "us-east-1a"
        5	
        6	  tags = { Name = "subred-privada-${var.nombre}" }
        7	}
        8	
        9	resource "aws_eip" "nat_eip" {
        10	  domain = "vpc"
        11	
        12	  tags = { Name = "eip-nat-${var.nombre}" }
        13	}
        14	
        15	resource "aws_nat_gateway" "nat_gw" {
        16	  allocation_id = aws_eip.nat_eip.id
        17	  subnet_id     = aws_subnet.subred_publica.id
        18	
        19	  tags = { Name = "nat-${var.nombre}" }
        20	
        21	  depends_on = [aws_internet_gateway.igw]
        22	}
        23	
        24	resource "aws_route_table" "private_rt" {
        25	  vpc_id = aws_vpc.main_vpc.id
        26	
        27	  route {
        28	    cidr_block     = "0.0.0.0/0"
        29	    nat_gateway_id = aws_nat_gateway.nat_gw.id
        30	  }
        31	
        32	  tags = { Name = "rt-privada-${var.nombre}" }
        33	}
        34	
        35	resource "aws_route_table_association" "private_rta" {
        36	  subnet_id      = aws_subnet.subred_privada.id
        37	  route_table_id = aws_route_table.private_rt.id
        38	}
    david@davidg:~/terraform-vpc$ 

**aws_subnet.subred_privada**: es una subred de 256 IPs que no tiene salida directa a Internet ni IP pública. Sirve para proteger servidores como una base de datos, que solo deben ser accesibles desde dentro de la red.

**aws_eip.nat_eip**: es la dirección IP pública que usará el NAT Gateway. Se la pedimos a AWS y es fija: mientras el NAT exista, siempre sale a Internet con la misma IP.

**aws_nat_gateway.nat_gw**: funciona como un intermediario. Las máquinas de la subred privada pueden pedirle que conecte con Internet, por ejemplo para descargar actualizaciones con *apt update*, pero desde fuera nadie puede iniciar una conexión hacia ellas. Se coloca en la **subred_publica** porque necesita salida a Internet.

**depends_on**: indica el orden de creación: primero el Internet Gateway y después el NAT Gateway, porque el NAT no funciona si el Internet Gateway aún no existe.

**aws_route_table** y **aws_route_table_association (privada)**: son la tabla de rutas de la subred privada y su asociación, igual que en la pública. La diferencia es el destino: el tráfico hacia Internet *0.0.0.0/0* se manda al NAT Gateway (*nat_gateway_id*) en lugar de al Internet Gateway.

---

### 5. Práctica DRY (Don't Repeat Yourself) - Creación dinámica de subredes

Esta práctica crea varias subredes a la vez, sin repetir el mismo bloque de código (DRY: *Don't Repeat Yourself*).

*Nota: Este código va en una carpeta aparte (`demo_dry/main.tf`) para que no se mezcle con la infraestructura de los pasos 1 a 4. Por eso usa otra red (`10.200.0.0/16`) y otros nombres.*

    david@davidg:~/terraform-vpc/demo_dry$ cat -n main.tf
        1	provider "aws" {
        2	  region = "us-east-1"
        3	}
        4	
        5	variable "nombre" {
        6	  type    = string
        7	  default = "david"
        8	}
        9	
        10	variable "numero_subredes" {
        11	  description = "Cantidad de subredes a desplegar"
        12	  type        = number
        13	  default     = 3
        14	}
        15	
        16	resource "aws_vpc" "vpc_demo" {
        17	  cidr_block = "10.200.0.0/16"
        18	
        19	  tags = { Name = "vpc-dry-${var.nombre}" }
        20	}
        21	
        22	resource "aws_subnet" "subredes_dinamicas" {
        23	  count             = var.numero_subredes
        24	  vpc_id            = aws_vpc.vpc_demo.id
        25	  availability_zone = "us-east-1a"
        26	  cidr_block        = cidrsubnet(aws_vpc.vpc_demo.cidr_block, 8, count.index)
        27	
        28	  tags = { Name = "subred-${var.nombre}-${count.index + 1}" }
        29	}
    david@davidg:~/terraform-vpc/demo_dry$

**variable "numero_subredes"**: es el número de subredes que se quieren crear.

**count = var.numero_subredes**: le dice a Terraform que cree la subred varias veces, tantas como indique la variable.

**cidrsubnet(...)**: calcula solo el rango de IPs de cada subred, para que no se repitan: *10.200.0.0/24*, *10.200.1.0/24* y *10.200.2.0/24*.

**Name = "subred-${var.nombre}-${count.index + 1}"**: le pone nombre a cada subred con mi nombre y un número. Como se cuenta desde 0, se suma 1 para que salga *subred-david-1*, *subred-david-2* y *subred-david-3*.