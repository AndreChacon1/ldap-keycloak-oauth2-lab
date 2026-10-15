# Resultado: ldap-keycloak-oauth2-lab

Revision analizada: `c998d437fa16f2e540d0ae55074ed191fd498f90`. Fecha local: 2026-10-14 (America/Mexico_City).

Coincidencias Nuclei: **37**. Cada matcher/endpoint puede generar una fila; no equivale a ese numero de vulnerabilidades distintas.

| Severidad Nuclei | Coincidencias |
| --- | ---: |
| critical | 0 |
| high | 0 |
| medium | 1 |
| low | 1 |
| info | 35 |

## Inventario completo

| Plantilla | Matcher | Endpoint | Severidad |
| --- | --- | --- | --- |
| swagger-api |  | http://api:8000/docs | info |
| cors-misconfig | arbitrary-origin | http://auth-gateway/realms/cybersecurity | info |
| nginx-version |  | http://auth-gateway/realms/cybersecurity | info |
| keycloak-openid-config |  | http://auth-gateway/realms/cybersecurity/.well-known/openid-configuration | info |
| phpldapadmin-panel |  | http://phpldapadmin | info |
| http-missing-security-headers | cross-origin-embedder-policy | http://api:8000 | info |
| http-missing-security-headers | cross-origin-opener-policy | http://api:8000 | info |
| http-missing-security-headers | cross-origin-resource-policy | http://api:8000 | info |
| http-missing-security-headers | strict-transport-security | http://api:8000 | info |
| http-missing-security-headers | x-frame-options | http://api:8000 | info |
| http-missing-security-headers | x-permitted-cross-domain-policies | http://api:8000 | info |
| http-missing-security-headers | content-security-policy | http://api:8000 | info |
| http-missing-security-headers | permissions-policy | http://api:8000 | info |
| http-missing-security-headers | x-content-type-options | http://api:8000 | info |
| http-missing-security-headers | referrer-policy | http://api:8000 | info |
| nginx-eol |  | http://auth-gateway | info |
| http-missing-security-headers | content-security-policy | http://auth-gateway/realms/cybersecurity | info |
| http-missing-security-headers | permissions-policy | http://auth-gateway/realms/cybersecurity | info |
| http-missing-security-headers | x-permitted-cross-domain-policies | http://auth-gateway/realms/cybersecurity | info |
| http-missing-security-headers | cross-origin-embedder-policy | http://auth-gateway/realms/cybersecurity | info |
| http-missing-security-headers | cross-origin-opener-policy | http://auth-gateway/realms/cybersecurity | info |
| http-missing-security-headers | cross-origin-resource-policy | http://auth-gateway/realms/cybersecurity | info |
| nginx-eol |  | http://auth-gateway/realms/cybersecurity | info |
| http-missing-security-headers | referrer-policy | http://phpldapadmin | info |
| http-missing-security-headers | cross-origin-embedder-policy | http://phpldapadmin | info |
| http-missing-security-headers | cross-origin-opener-policy | http://phpldapadmin | info |
| http-missing-security-headers | cross-origin-resource-policy | http://phpldapadmin | info |
| http-missing-security-headers | strict-transport-security | http://phpldapadmin | info |
| http-missing-security-headers | content-security-policy | http://phpldapadmin | info |
| http-missing-security-headers | permissions-policy | http://phpldapadmin | info |
| http-missing-security-headers | x-permitted-cross-domain-policies | http://phpldapadmin | info |
| ldap-metadata |  | openldap:389 | info |
| ldap-anonymous-login-detect |  | openldap:389 | medium |
| tls-version |  | auth-gateway:636 | info |
| mismatched-ssl-certificate |  | auth-gateway:636 | info |
| ssl-dns-names |  | auth-gateway:636 | info |
| untrusted-root-certificate |  | auth-gateway:636 | low |

## Evaluacion

- Cabeceras ausentes: evidencia de configuracion, de severidad informativa en la plantilla. Priorizar CSP, nosniff, proteccion de framing y Referrer-Policy donde correspondan; validar compatibilidad antes de cambiar politicas entre origenes. HSTS necesita un despliegue HTTPS previo.
- Version de Nginx: banner confirmado; la alerta upstream EOL necesita evaluacion de parches Debian. Paquete instalado: `1.22.1-9+deb12u10`. No se confirma una CVE por el banner.
- No se realizaron correcciones en esta entrega. Conservar esta linea base para comparar con la fase posterior de commits granulares.

Consultar `../README.md` para cobertura y limitaciones. `scan.log` contiene conteos, duracion y finalizacion; `errors.log` registra errores de solicitudes. Los JSONL son la salida de Nuclei, sin solicitudes/respuestas crudas. `connectivity-before.txt` y `connectivity-after.txt` prueban conectividad desde el escaner.

## Validacion especifica del laboratorio

- **LDAP anonimo (medium): bind confirmado.** `ldapwhoami -x` devuelve `anonymous`. La consulta anonima de la base `dc=example,dc=com` devuelve LDAP 32 y no entrega entradas. Se confirma el bind, pero NO una lectura de usuarios ni una filtracion del directorio. Evaluar si el laboratorio necesita bind anonimo/RootDSE antes de restringirlo; comprobar despues Keycloak y phpLDAPadmin. Evidencia: `anonymous-directory-validation.txt`.
- **CA no confiable (low): contexto de CA privada.** Nuclei no confia en la CA del laboratorio. OpenSSL con esa CA y `-verify_hostname localhost` devuelve `Verify return code: 0 (ok)`. No se confirma una cadena rota para clientes configurados correctamente; distribuir la CA a los clientes autorizados. Evidencia: `tls-validation.txt`.
- **Nombre TLS distinto (info): alias de escaneo.** Se analizo `auth-gateway:636`, pero el certificado cubre `openldap`, `localhost` y la IP documentada del laboratorio. La validacion para `localhost` es correcta. Si se va a usar `auth-gateway` como identidad TLS de cliente, agregarlo al SAN y regenerar el certificado; no desactivar la validacion.
- **CORS (info): comportamiento confirmado, impacto no demostrado.** El endpoint publico del realm refleja `Origin` y envia `Access-Control-Allow-Credentials: true`. La respuesta sin sesion contiene realm, clave publica y URLs del servicio. No se ha demostrado acceso a datos privados ni extrapolado el comportamiento a endpoints autenticados. Evidencia: `cors-validation.txt`.
- **Swagger/phpLDAPadmin/OIDC (info): superficies identificadas.** Swagger y phpLDAPadmin se publican en loopback; su visibilidad interna esta confirmada. OIDC discovery publica metadatos necesarios para clientes y no constituye por si mismo una vulnerabilidad. Revisar restricciones de documentacion y administracion segun el destino del despliegue.
- **Metadatos LDAP (info): dato de plantilla no validado.** La salida `BaseDN: dc=389` no coincide con el naming context `dc=example,dc=com` observado mediante ldapsearch. Conservar la salida original, pero no utilizar ese valor como inventario fiable.

HTTP: 62 plantillas, 31 coincidencias, cero errores. LDAP: 2 plantillas, 2 coincidencias. TLS: 38 plantillas, 4 coincidencias. El script completo termino con codigo 0; los errores HTTP y LDAP estan vacios; TLS contiene 13 errores de negociacion investigados abajo. No hubo hallazgos high/critical en este alcance selectivo.

## Orden propuesto de commits de correccion

1. Restriccion de bind anonimo, si se confirma que no es necesario, con pruebas de federacion LDAP y administracion.
2. Cabeceras HTTP por superficie, con validacion de login, Swagger e integraciones.
3. Restricciones de superficies administrativas/documentacion segun el entorno objetivo.
4. Identidad/confianza TLS para los nombres realmente usados; no sustituir la CA privada solo para silenciar el escaner.
5. CORS o actualizacion Nginx solo si la validacion adicional confirma un riesgo que requiera ese cambio.

Cada correccion confirmada debe tener su propio commit y reescaneo. Los hallazgos de contexto o falsos positivos deben cerrarse con justificacion, no mediante cambios indiscriminados.

## Investigacion de errores de puerto/TLS

`tls-errors.log` contiene 13 errores genericos `could not connect to host`. Se repitieron las 38 plantillas directamente en `openldap:636` (misma red auth-network, sin gateway): los mismos 13 errores persistieron, mientras TLS 1.2, SAN y CA privada se detectaron correctamente (3 coincidencias). Los resultados complementarios no se suman a las 37 coincidencias de la linea base.

Comando de contraste: `nuclei -u openldap:636 -t ssl/ -duc -ni -rl 2 -c 1 -nc -or -ot -jle /tmp/tls-direct.jsonl -elog /tmp/tls-direct-errors.log`.

OpenSSL confirma negociacion TLS 1.2; los intentos TLS 1.0, 1.1 y 1.3 terminan sin sesion. Ver `tls-protocol-validation.txt`. Por tanto, no es una inaccesibilidad general del puerto ni falta de bridge; las pruebas de protocolos/cifrados no negociables generan errores. No se considera que todas las comprobaciones TLS hayan pasado.

Fail2Ban registro un bloqueo del escaner en LDAPS a las 02:40:14 UTC, despues del escaneo TLS de las 02:40:13, y su desbloqueo a las 02:41:13. HTTP no tuvo bloqueos. El reescaneo directo evita la proteccion del gateway y reproduce los errores, por lo que el bloqueo no explica esos resultados. No se desactivo Fail2Ban ni se agregaron excepciones persistentes.
