# Cri script

Asistente de ejecución remota de scripts en bash.

Este script de bash, toma como entrada un archivo config de ssh con una lista de servidores así como un script a ejecutar en cada uno de ellos.

Es un auxiliar para ejecutar un script en varios servidores de forma secuencial.


## Instalación

```bash
curl  https://raw.githubusercontent.com/everitosan/BashScripts/main/cri/cri.sh -o /usr/local/bin/cri && chmod +X /usr/local/bin/cri
```


**Parámetros**

```bash
$ cri -h


█─▄▄▄─█▄─▄▄▀█▄─▄█
█─███▀██─▄─▄██─██
▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▀  (0.0.1)

Ejecución remota de scripts
  
Opciones:

  -s [ruta de config con hostnames de los servidores]
  -a [ruta de script a ejecutar en elos servidores remotamente]
* -i [índice del servidor a afectar]
* -p [bandera para indicar si usará contraseña escrita en password.txt]

* Parámetros opcionales
```

**-s**  
*El archivo config es como cualquier config de ssh, es script hara uso del `Host` definido para intentar la ejecución.*

Ejemplo de config:
```bash
######
# Server 1
######
Host <server-name>
  Hostname <server-ip>
  Port 22
  User <User>
  ServerAliveInterval 60
  IdentityFile <path-to-server-key>

######
# Server 2
######
Host <server-name>
  Hostname <server-ip>
  Port 22
  User <User>
  ServerAliveInterval 60
  IdentityFile <path-to-server-key>
```

**-a**  
*El archivo a ejecutar puede contener cualquier código bash válido, los permisos dependerán ya del usuario con el que se ejecuta el script.*

Ejemplo de script:

```bash
#!/bin/bash
ls;
```

**-p**  
*Si se incluye esta bandera en la ejecución, el script intentará hacer uso de [sshpass](https://linux.die.net/man/1/sshpass), por lo que debe existir un archivo `password.txt` al mismo nivel de la ejecución del script.*

Ejemplo de password.txt:

```
Contraseñ4SuperSecret4DelServidor
```
