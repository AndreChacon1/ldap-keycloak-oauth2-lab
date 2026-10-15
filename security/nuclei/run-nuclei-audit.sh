#!/bin/sh
set -eu
mkdir -p /tmp/audit/frontend /tmp/audit/backend /tmp/audit/ldap
nuclei -tags nginx,keycloak,ldap,phpldapadmin,express,fastapi -pt http -etags dos,fuzz,bruteforce -ni -tl -silent -duc -nc | sed -n '/^http\/.*\.yaml$/p' > /tmp/http-templates.txt
for file in http/misconfiguration/http-missing-security-headers.yaml http/vulnerabilities/generic/cors-misconfig.yaml http/exposures/configs/git-config.yaml http/exposures/apis/swagger-api.yaml; do
  echo "/root/nuclei-templates/$file" >> /tmp/http-templates.txt
done
for component in frontend backend ldap; do
  case "$component" in
    frontend) targets='http://frontend' ;;
    backend) targets='http://backend
http://backend/health
http://backend/api/games' ;;
    ldap) targets='http://auth-gateway
http://auth-gateway/realms/cybersecurity
http://phpldapadmin
http://api:8000' ;;
  esac
  out=/tmp/audit/$component
  printf '%s\n' "$targets" > "$out/targets.txt"
  cp /tmp/http-templates.txt "$out/templates.txt"
  nuclei -version > "$out/version.txt" 2>&1
  nuclei -tv >> "$out/version.txt" 2>&1
  nuclei -l "$out/targets.txt" -t "$out/templates.txt" -duc -ni -etags dos,fuzz,bruteforce -rl 3 -c 2 -bs 1 -timeout 5 -retries 1 -nc -or -ot -jle "$out/findings.jsonl" -elog "$out/errors.log" -stats -si 30 > "$out/scan.log" 2>&1
  echo "$?" > "$out/exit-code.txt"
done
nuclei -u openldap:389 -t javascript/misconfiguration/ldap/ldap-anonymous-login-detect.yaml -t javascript/enumeration/ldap/ldap-metadata.yaml -duc -ni -rl 2 -c 1 -nc -or -ot -jle /tmp/audit/ldap/ldap-findings.jsonl -elog /tmp/audit/ldap/ldap-errors.log > /tmp/audit/ldap/ldap-scan.log 2>&1
nuclei -u auth-gateway:636 -t ssl/ -duc -ni -rl 2 -c 1 -nc -or -ot -jle /tmp/audit/ldap/tls-findings.jsonl -elog /tmp/audit/ldap/tls-errors.log > /tmp/audit/ldap/tls-scan.log 2>&1