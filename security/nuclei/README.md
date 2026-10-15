# Analisis Nuclei - 14 de octubre de 2026

Esta entrega conserva la linea base ANTES de correcciones. Ver `2026-10-14/REPORT.md` para el resultado propio de este repositorio. Los timestamps UTC del 15 de octubre corresponden a la noche del 14 en America/Mexico_City.

## Procedimiento ejecutado

1. Iniciar los tres proyectos con Docker Compose, conservando sus volumenes.
2. Crear el contenedor de Nuclei y unirlo a las dos redes existentes:

```powershell
docker run --name nuclei-dashboard-audit --network dashboard-lab --entrypoint sh -d projectdiscovery/nuclei@sha256:582d5546902e67052097cb2d07296c642d50a1afc5e44623cb038845df9a32eb -c 'sleep 86400'
docker network connect ldap-keycloak-oauth2-lab_auth-network nuclei-dashboard-audit
docker exec nuclei-dashboard-audit nuclei -ut -nc
docker cp security/nuclei/run-nuclei-audit.sh nuclei-dashboard-audit:/tmp/run.sh
docker exec nuclei-dashboard-audit sh /tmp/run.sh
```

El script examina los TRES proyectos. Copiar exclusivamente el resultado correspondiente a cada repositorio desde `/tmp/audit/frontend`, `/tmp/audit/backend` o `/tmp/audit/ldap` con `docker cp`. Usar un directorio nuevo para cada ejecucion. El nombre del contenedor debe estar disponible; al terminar se puede eliminar exclusivamente ese contenedor con `docker rm -f nuclei-dashboard-audit`.

Version ejecutada: Nuclei 3.11.1, plantillas oficiales v10.5.0. `-ut` obtiene las plantillas vigentes al repetir; para reproducir exactamente esta seleccion instalar previamente el tag v10.5.0 de https://github.com/projectdiscovery/nuclei-templates y contrastar `template-sha256.txt`. El digest de imagen fija el motor. No se habilita subida a la nube ni Interactsh.

## Red y cobertura

El escaner comparte las redes bridge `dashboard-lab` y `ldap-keycloak-oauth2-lab_auth-network`. `localhost` dentro del escaner NO representa al servicio analizado. Se utilizan nombres DNS Docker y puertos internos: frontend:80, backend:80, auth-gateway:80/636, phpldapadmin:80, api:8000 y openldap:389. Los endpoints HTTP y puertos TCP fueron comprobados desde el mismo contenedor de Nuclei antes y despues del analisis.

Se ejecutan 62 plantillas HTTP firmadas: seleccion por tecnologias nginx/keycloak/ldap/phpldapadmin/express/fastapi y comprobaciones generales de cabeceras, CORS, Git expuesto y Swagger. LDAP agrega dos plantillas JavaScript (bind anonimo y metadatos) y las plantillas SSL contra el gateway LDAPS. `templates.txt` y los logs registran el alcance efectivo. Se limita HTTP a 3 solicitudes/s, concurrencia 2, para convivir con Fail2Ban.

## Interpretacion y limites

- Nuclei analiza servicios en ejecucion, no todo el codigo fuente, las dependencias ni la configuracion de los repositorios. No constituye una auditoria exhaustiva.
- Escaneo sin autenticacion, sin cobertura de rutas protegidas con una sesion valida, ni navegador headless, OAST, fuzzing, DoS o fuerza bruta. La ausencia de coincidencias no demuestra ausencia de vulnerabilidades.
- El bridge permite examinar superficies internas. Una deteccion interna no implica que sea accesible desde Internet. phpLDAPadmin y FastAPI se publican solo en loopback; LDAP:389 no se publica al host.
- Los resultados `info` incluyen inventario y recomendaciones. Las cabeceras se evaluan segun contenido y contexto: HSTS requiere HTTPS; COOP/COEP/CORP pueden afectar integraciones; no se deben activar indiscriminadamente.
- `nginx-eol` compara el banner 1.22.1 con una version upstream. El paquete instalado es `1.22.1-9+deb12u10`; el matcher no comprueba los parches de Debian. Su resultado no confirma una CVE explotable.
- Los JSONL omiten solicitudes/respuestas crudas y el cuerpo codificado de plantillas. No contienen sesiones de usuario aportadas al escaner. Conservar los resultados originales separados de la evaluacion humana.

## Seguimiento

Tras entregar esta linea base, registrar las excepciones indicadas por el solicitante. Las correcciones de hallazgos confirmados se haran con commits independientes por problema y evidencia de reescaneo, conservando esta carpeta original. Los hallazgos informativos necesitan clasificacion antes de convertirlos en cambios funcionales.

Referencia del motor: https://github.com/projectdiscovery/nuclei
La validacion TLS genero errores de negociacion y un bloqueo LDAPS posterior a la primera prueba. Se repitio directamente contra openldap:636; ver el informe del repositorio LDAP para la evidencia y las limitaciones. La limitacion -rl no evito la rafaga de handshakes SSL. Para repetir TLS preferir el destino directo dentro de auth-network.
