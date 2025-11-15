# 🔗 Configuración Conexión OpenScan ↔ Paperless

**Objetivo:** Conectar la app móvil OpenScan con servidor Paperless-ngx

---

## 📍 Paso 1: Identificar IP del Servidor Paperless

### Obtener IP de tu máquina

```bash
# Ver todas las IPs
ip addr show

# O más simple
hostname -I | awk '{print $1}'
```

**Ejemplo de output:**
```
192.168.1.100  ← Esta es tu IP local
```

---

## 🌐 Paso 2: Exponer Paperless en la Red Local

### Verificar Puerto Actual

```bash
cd /home/smt/Escritorio/programacion_proyectos/paperless/paperless-ngx
docker compose ps
```

**Buscar línea:**
```
paperless-ngx-webserver-1   0.0.0.0:8001->8000/tcp
```

Si dice `127.0.0.1:8001` en lugar de `0.0.0.0:8001`, necesitas cambiar:

### Editar docker-compose.yml

```bash
nano docker-compose.yml
```

**Buscar sección webserver:**

```yaml
services:
  webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    ports:
      - "0.0.0.0:8001:8000"  # ← Cambiar a 0.0.0.0 para acceso externo
```

**Guardar:** Ctrl+O, Enter, Ctrl+X

### Reiniciar Paperless

```bash
docker compose down
docker compose up -d
```

---

## 🔥 Paso 3: Configurar Firewall

### Permitir Tráfico en Puerto 8001

```bash
# UFW (Ubuntu)
sudo ufw allow 8001/tcp

# Verificar
sudo ufw status
```

**Debería mostrar:**
```
8001/tcp                   ALLOW       Anywhere
```

---

## 📱 Paso 4: Configurar OpenScan

### Opción A: URL Dinámica (Recomendado)

En LoginScreen, el usuario ingresa:
- **URL:** `http://192.168.1.100:8001` (cambiar por tu IP)
- **Usuario:** `admin`
- **Password:** `admin`

✅ **No requiere recompilar app**

### Opción B: URL Hardcoded

Si quieres que la URL esté preconfigura en la app:

**Editar:** `lib/core/constants/api_constants.dart`

```dart
static const String defaultBaseUrl = 'http://192.168.1.100:8001';
```

**Cambiar `192.168.1.100` por tu IP real.**

Luego recompilar:
```bash
flutter build apk --release
```

---

## 🧪 Paso 5: Probar Conexión

### Desde PC (mismo que servidor)

```bash
curl http://localhost:8001/api/
```

**Debería retornar JSON:**
```json
{
  "version": "2.x.x",
  ...
}
```

### Desde Dispositivo Móvil

**Conectar dispositivo a la MISMA WiFi que el servidor.**

Abrir navegador en el dispositivo:
```
http://192.168.1.100:8001
```

**Debería cargar la interfaz web de Paperless.**

Si carga ✅ → OpenScan podrá conectarse
Si NO carga ❌ → Hay problema de red/firewall

---

## 🔑 Paso 6: Obtener Token de Autenticación (Opcional)

Si quieres usar token fijo en lugar de login:

### Generar Token en Paperless

```bash
# Entrar al contenedor
docker exec -it paperless-ngx-webserver-1 bash

# Crear token
python3 manage.py drf_create_token admin

# Output:
# Generated token abc123def456... for user admin
```

### Configurar en OpenScan

**Editar:** `lib/core/config/env_config.dart`

```dart
static const String paperlessApiToken = 'abc123def456...';
```

---

## 📋 Resumen de URLs por Escenario

| Escenario | URL a usar |
|-----------|-----------|
| **Emulador Android en misma PC** | `http://10.0.2.2:8001` |
| **Dispositivo físico en misma WiFi** | `http://192.168.X.X:8001` |
| **Servidor remoto con dominio** | `https://paperless.tudominio.com` |
| **Servidor remoto con IP pública** | `http://X.X.X.X:8001` |

---

## 🔒 Paso 7: HTTPS (Opcional pero Recomendado)

Si quieres usar HTTPS:

### Con Nginx Reverse Proxy

```bash
sudo apt install nginx certbot python3-certbot-nginx

# Configurar nginx
sudo nano /etc/nginx/sites-available/paperless
```

**Contenido:**
```nginx
server {
    listen 80;
    server_name paperless.tudominio.com;

    location / {
        proxy_pass http://localhost:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Habilitar sitio
sudo ln -s /etc/nginx/sites-available/paperless /etc/nginx/sites-enabled/

# Certificado SSL
sudo certbot --nginx -d paperless.tudominio.com

# Reiniciar nginx
sudo systemctl restart nginx
```

**Luego en OpenScan usar:**
```
https://paperless.tudominio.com
```

---

## 🧪 Testing Completo

### 1. Test desde curl

```bash
# Test básico
curl -I http://192.168.1.100:8001

# Test API
curl http://192.168.1.100:8001/api/

# Test auth
curl -X POST http://192.168.1.100:8001/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

### 2. Test desde navegador móvil

En dispositivo Android, abrir Chrome:
```
http://192.168.1.100:8001
```

### 3. Test desde OpenScan

1. Abrir app
2. LoginScreen
3. Ingresar:
   - URL: `http://192.168.1.100:8001`
   - User: `admin`
   - Pass: `admin`
4. Tap "Iniciar Sesión"

**Esperado:** Navega a PersonSelectionScreen

---

## 🐛 Troubleshooting

### Error: "No se puede conectar"

**Verificar:**
```bash
# 1. Paperless corriendo
docker compose ps | grep webserver

# 2. Puerto abierto
netstat -tulpn | grep 8001

# 3. Firewall
sudo ufw status | grep 8001

# 4. Ping desde dispositivo
# En dispositivo, terminal app:
ping 192.168.1.100
```

### Error: "Connection refused"

**Causa:** Puerto no expuesto en 0.0.0.0

**Solución:** Revisar Paso 2

### Error: "Network unreachable"

**Causa:** Dispositivo no en misma red

**Solución:**
- Conectar dispositivo a misma WiFi
- O usar IP pública + port forwarding en router

### Error: "Invalid token"

**Causa:** Token expirado o incorrecto

**Solución:** Re-login para obtener nuevo token

---

## 📊 Configuración Final Recomendada

### Para Desarrollo/Testing:

```dart
// lib/core/constants/api_constants.dart
static const String defaultBaseUrl = 'http://192.168.1.100:8001';
```

```yaml
# docker-compose.yml
ports:
  - "0.0.0.0:8001:8000"
```

```bash
# Firewall
sudo ufw allow 8001/tcp
```

### Para Producción:

1. ✅ Usar HTTPS con certificado SSL
2. ✅ Cambiar password default de admin
3. ✅ Usar token de autenticación
4. ✅ Configurar rate limiting
5. ✅ Firewall más restrictivo (solo IPs específicas)

---

## 🎯 Checklist de Configuración

- [ ] IP del servidor identificada
- [ ] Paperless expuesto en 0.0.0.0:8001
- [ ] Firewall permite puerto 8001
- [ ] Navegador móvil carga Paperless
- [ ] OpenScan configurado con IP correcta
- [ ] Login funciona desde app
- [ ] Census data carga (3,997 personas)
- [ ] Upload de prueba exitoso

---

## 📞 URLs de Referencia

**Paperless API Docs:**
```
http://192.168.1.100:8001/api/docs/
```

**Paperless Admin:**
```
http://192.168.1.100:8001/admin/
```

**Census Data Location:**
```
OpenScan/assets/census/persons.csv
```

---

## ✅ CONFIGURACIÓN LISTA

Una vez completados todos los pasos:

1. ✅ Paperless accesible desde red local
2. ✅ OpenScan sabe dónde conectarse
3. ✅ Firewall configurado
4. ✅ Testing completado

**Próximo paso:** Generar APK y probar upload de documentos.
