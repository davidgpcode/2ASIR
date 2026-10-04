# Backup de configuraciones de routers por SSH

## Mikrotik-1

1. Grupo con solo lectura y SSH, y usuario en ese grupo:
   ```
   /user group add name=backup policy=ssh,read,test
   /user add name=backup group=backup password=<clave>
   ```
2. Subir la clave pública (`scp ~/.ssh/id_backup.pub admin@IP:`) e importarla:
   ```
   /user ssh-keys import public-key-file=id_backup.pub user=backup
   ```
3. Extracción (`export terse` oculta los datos sensibles):
   ```bash
   ssh -i ~/.ssh/id_backup backup@192.168.122.144 "/export terse" > ~/configs/mikrotik-1.rsc
   ```
4. Prueba de permisos: `/ip address add ...` por SSH devuelve `not enough permissions`.

---

## Vyos-1

1. Dar IP a `eth0` y activar SSH: `set interfaces ethernet eth0 address dhcp` y `set service ssh`.
2. Crear el usuario con la clave pública:
   ```
   set system login user respaldo authentication public-keys pc type ssh-ed25519
   set system login user respaldo authentication public-keys pc key <clave base64>
   commit
   save
   ```
3. Quitarle privilegios (VyOS lo mete en `sudo`, `disk`, `adm`...) y fijar su shell para que solo muestre la configuración:
   ```bash
   sudo usermod -G users,vyattacfg respaldo
   printf '#!/bin/bash\nexec cat /config/config.boot\n' | sudo tee /usr/local/bin/cfgcat
   sudo chmod 755 /usr/local/bin/cfgcat
   echo /usr/local/bin/cfgcat | sudo tee -a /etc/shells
   sudo usermod -s /usr/local/bin/cfgcat respaldo
   ```
4. Extracción y ocultar el hash de contraseña:
   ```bash
   ssh -T -i ~/.ssh/id_backup respaldo@192.168.122.153 "leer" > ~/configs/vyos-1.cfg
   sed -i -E 's/(encrypted-password) .*/\1 "<OCULTO>"/' ~/configs/vyos-1.cfg
   ```
5. Prueba: cualquier orden que se pida (`configure`, `id`...) devuelve solo `config.boot`.

Notas: no tocar `/etc/ssh` ni reiniciar `ssh.service` (VyOS usa `ssh@default.service`). Si el SSH deja de arrancar, `delete service ssh` y `set service ssh` en modo configuración lo regeneran. VyOS arranca desde ISO live: lo configurado se pierde al reiniciar el nodo.

---

## R_Linux-1

Se entra desde el PC con `docker exec -it <id> sh`. Dentro:

1. Dar IP por DHCP e instalar SSH y sudo: `udhcpc -i eth0 -n` y `apk add openssh sudo`.
2. Crear el usuario (con contraseña aleatoria para que Alpine no bloquee la cuenta):
   ```sh
   adduser -D -s /bin/sh respaldo
   echo "respaldo:$(head -c 24 /dev/urandom | base64)" | chpasswd
   ```
3. Clave pública con orden forzada en `~/.ssh/authorized_keys`:
   ```
   command="/usr/local/bin/cfgdump",no-pty,no-port-forwarding,no-agent-forwarding,no-X11-forwarding ssh-ed25519 <clave> backup-routers
   ```
4. Script `cfgdump` (muestra `ip addr`, `ip route`, `iptables-save` y `ip_forward`) y `sudo` limitado a esa única orden:
   ```sh
   echo 'respaldo ALL=(root) NOPASSWD: /sbin/iptables-save' > /etc/sudoers.d/respaldo
   ```
5. Arrancar el servidor: `ssh-keygen -A && /usr/sbin/sshd`.
6. Extracción:
   ```bash
   ssh -T -i ~/.ssh/id_backup respaldo@192.168.122.228 "leer" > ~/configs/r-linux-1.cfg
   ```

---

## Cisco-1

1. IP en la interfaz que va al switch (`Gi0/0`) y SSH:
   ```
   ip domain-name lab.local
   crypto key generate rsa modulus 2048
   ip ssh version 2
   ```
2. Usuario de privilegio 1 que solo puede ver la configuración:
   ```
   username backup privilege 1 secret <clave>
   privilege exec level 1 show running-config
   ```
3. Clave pública RSA y acceso solo por SSH:
   ```
   ip ssh pubkey-chain
    username backup
     key-string
      <bloque base64 de id_backup_rsa.pub>
     exit
    exit
   line vty 0 4
    login local
    transport input ssh
   ```
4. Extracción (IOS 15.9 necesita algoritmos antiguos):
   ```bash
   ssh -i ~/.ssh/id_backup_rsa \
     -o KexAlgorithms=+diffie-hellman-group14-sha1 \
     -o HostKeyAlgorithms=+ssh-rsa \
     -o PubkeyAcceptedAlgorithms=+ssh-rsa \
     backup@192.168.122.210 "show running-config" > ~/configs/cisco-1.cfg
   ```
5. Ocultar datos:
   ```bash
   sed -i -E 's/(secret [0-9]+) .*/\1 <OCULTO>/; s/(password [0-9]+) .*/\1 <OCULTO>/' ~/configs/cisco-1.cfg
   ```

---