#!/bin/bash
set -euo pipefail
mkdir -p /run/fail2ban /var/log/nginx
touch /var/log/nginx/access.log /var/log/nginx/error.log /var/log/nginx/ldaps.log
rm -f /run/fail2ban/fail2ban.sock /run/fail2ban/fail2ban.pid
nginx -t
fail2ban-client -x start
pids=()
cleanup() {
  fail2ban-client stop || true
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
  wait || true
}
trap cleanup EXIT
trap 'exit 143' TERM INT
if [ -f /app/src/server.js ]; then
  node /app/src/server.js &
  pids+=("$!")
fi
nginx -g 'daemon off;' &
pids+=("$!")
# Exit the container if the firewall daemon dies, too.
(while sleep 5; do fail2ban-client ping >/dev/null || exit 1; done) &
pids+=("$!")
set +e
wait -n "${pids[@]}"
exit 1
