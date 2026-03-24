# Wazuh SIEM Lab – single-node + attacker01 + victim01

Procedimiento único para levantar **todos los contenedores** del laboratorio en un solo flujo:

- **Wazuh manager**
- **Wazuh indexer**
- **Wazuh dashboard**
- **victim01**: Ubuntu con `sshd`, `rsyslog` y `wazuh-agent`
- **attacker01**: Ubuntu con `nmap`, `hydra` y cliente SSH

Este README unifica el despliegue base de Wazuh en modo **single-node** y el despliegue adicional de **attacker01** y **victim01**. El despliegue base usa un `docker-compose.yml` con **un manager, un indexer y un dashboard**. Antes de iniciar, en Linux se debe ajustar `vm.max_map_count=262144`, generar certificados con `generate-indexer-certs.yml`, y luego levantar el entorno con `docker compose up -d`. El complemento del laboratorio agrega `victim01` y `attacker01`, conectados a la red del stack oficial, y se levanta combinando `docker-compose.yml` con `docker-compose.lab.yml`. Ambos comportamientos provienen de los README adjuntos. fileciteturn4file1 fileciteturn4file0

---

## 1. Estructura esperada

Ubícate en la carpeta del laboratorio. Debes tener, como mínimo:

```text
single-node/
├── docker-compose.yml
├── docker-compose.lab.yml
├── generate-indexer-certs.yml
├── attacker/
│   └── Dockerfile
├── victim/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── ossec.conf
│   └── sshd_config
└── config/
    └── ...
```

---

## 2. Preparación del host

En Linux, ejecuta:

```bash
sudo sysctl -w vm.max_map_count=262144
```

---

## 3. Generación de certificados

Ejecuta:

```bash
sudo docker compose -f generate-indexer-certs.yml run --rm generator
```

Si el proyecto ya incluye la carpeta de certificados funcional y no necesitas regenerarlos, este paso puede omitirse. Si aparecen errores de montaje de archivos `.pem`, regenera primero los certificados.

---

## 4. Levantar todo el laboratorio en un solo comando

Desde la carpeta `single-node/`, ejecuta:

```bash
sudo docker compose -f docker-compose.yml -f docker-compose.lab.yml up -d --build
```

Este comando levanta:

- el stack principal de Wazuh
- los contenedores `victim01` y `attacker01`

---

## 5. Verificación de contenedores

```bash
sudo docker ps
```

Deberías ver en estado `Up`:

- `wazuh.manager`
- `wazuh.indexer`
- `wazuh.dashboard`
- `victim01`
- `attacker01`

> La primera vez el entorno puede tardar cerca de un minuto mientras Wazuh Indexer inicializa índices y patrones.

---

## 6. Acceso a Wazuh

Abre en el navegador:

```text
https://localhost
```

Credenciales usadas en el laboratorio:

```text
Usuario: admin
Password: SecretPassword
```

---

## 7. Validación de red

Entra al contenedor atacante:

```bash
sudo docker exec -it attacker01 bash
```

Pruebas básicas:

```bash
ping -c 2 victim01
nmap -sV victim01
```

La validación esperada es conectividad correcta y puerto `22/tcp` abierto en la víctima. El README del add-on propone precisamente esta validación con `ping` y `nmap`. fileciteturn4file0

---

## 8. Validación del agente de la víctima

Revisa el agente:

```bash
sudo docker exec -it victim01 bash
tail -n 50 /var/ossec/logs/ossec.log
```

En la interfaz de Wazuh:

- entra a **Agents**
- espera 1 a 2 minutos
- `victim01` debe aparecer conectado

El README del add-on también indica esta validación y el uso de `docker logs victim01` como apoyo. fileciteturn4file0

---

## 9. Usuario de prueba en la víctima

```text
usuario: demo
contraseña: Demo123!
```

---

## 10. Generación de eventos para la demo

### 10.1 Ataque desde attacker01

Dentro de `attacker01`:

```bash
printf 'admin\n123456\nqwerty\nDemo123!\n' > /tmp/passlist.txt
hydra -l demo -P /tmp/passlist.txt ssh://victim01 -t 4 -V
```

### 10.2 Acceso SSH manual

```bash
ssh demo@victim01
```

### 10.3 Cambio de archivo para FIM

Dentro de `victim01` como root:

```bash
echo "intrusion $(date)" >> /opt/lab/crownjewels.txt
```

> En algunos montajes Docker, los eventos SSH reales no siempre se reflejan en `auth.log` como en una VM completa. Si el laboratorio está configurado con `lab_auth.log` o `fake_auth.log`, asegúrate de crear esos archivos y reiniciar el agente antes de la demo.

---

## 11. Validación en Wazuh

En la GUI, revisa:

- **Threat Hunting**
- **Events**
- filtro recomendado:

```text
agent.name: victim01
```

Eventos esperados:

- actividad del agente
- eventos de syslog
- eventos FIM sobre `/opt/lab/crownjewels.txt`
- eventos de autenticación si el parser/logsource está correctamente configurado

---

## 12. Troubleshooting rápido

### 12.1 Docker no conecta al daemon

Prueba primero:

```bash
sudo docker ps
sudo docker compose version
```

### 12.2 Indexer o dashboard no levantan

Revisa logs:

```bash
sudo docker compose logs --tail=100 wazuh.indexer
sudo docker compose logs --tail=100 wazuh.dashboard
sudo docker compose logs --tail=100 wazuh.manager
```

### 12.3 Error con certificados `.pem`

Regenera certificados:

```bash
sudo docker compose down -v
sudo docker compose -f generate-indexer-certs.yml run --rm generator
sudo docker compose -f docker-compose.yml -f docker-compose.lab.yml up -d --build
```

### 12.4 El agente no aparece

Dentro de `victim01`:

```bash
/var/ossec/bin/wazuh-control restart
tail -n 100 /var/ossec/logs/ossec.log
```

### 12.5 No aparecen eventos SSH

Crea los archivos si tu `ossec.conf` los referencia:

```bash
touch /var/log/lab_auth.log /var/log/fake_auth.log
chmod 644 /var/log/lab_auth.log /var/log/fake_auth.log
/var/ossec/bin/wazuh-control restart
```

Y genera eventos controlados:

```bash
echo "Mar 24 20:40:01 victim01 sshd[1234]: Failed password for invalid user admin from 172.19.0.6 port 54522 ssh2" >> /var/log/lab_auth.log
echo "Mar 24 20:40:09 victim01 sshd[9999]: Accepted password for demo from 172.19.0.6 port 54522 ssh2" >> /var/log/lab_auth.log
```

---

## 13. Apagado del laboratorio

Para bajar todo:

```bash
sudo docker compose -f docker-compose.yml -f docker-compose.lab.yml down
```

Si también quieres eliminar volúmenes:

```bash
sudo docker compose -f docker-compose.yml -f docker-compose.lab.yml down -v
```

---

## 14. Resumen operativo

Comandos mínimos:

```bash
cd ~/ruta/al/proyecto/single-node
sudo sysctl -w vm.max_map_count=262144
sudo docker compose -f generate-indexer-certs.yml run --rm generator
sudo docker compose -f docker-compose.yml -f docker-compose.lab.yml up -d --build
sudo docker ps
```

Con eso queda levantado el escenario completo en un solo flujo.
