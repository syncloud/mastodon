#!/bin/bash -e

APP_DOMAIN=$1

for i in $(seq 1 120); do
  CODE=$(curl -skL -o /dev/null -w '%{http_code}' "https://${APP_DOMAIN}" || true)
  if [ "$CODE" -ge 200 ] 2>/dev/null && [ "$CODE" -lt 400 ]; then
    if curl -skL "https://${APP_DOMAIN}/auth/sign_in" | grep -q 'user_email'; then
      echo "${APP_DOMAIN} is ready"
      exit 0
    fi
    echo "waiting for ${APP_DOMAIN} sign-in form, root answered ${CODE}"
  else
    echo "waiting for ${APP_DOMAIN}, got ${CODE}"
  fi
  sleep 5
done

echo "${APP_DOMAIN} did not become ready"
exit 1
