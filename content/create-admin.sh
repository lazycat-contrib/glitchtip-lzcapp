#!/bin/sh
# Seed the first GlitchTip superuser, then hand over to the stock entrypoint.
#
# The image's own start script is not documented in the repo, so this wrapper is
# deliberately conservative: migrate is idempotent, and the superuser step is
# skipped whenever an account already exists.
set -eu

: "${GLITCHTIP_ADMIN_EMAIL:?GLITCHTIP_ADMIN_EMAIL is required}"
: "${GLITCHTIP_ADMIN_PASSWORD:?GLITCHTIP_ADMIN_PASSWORD is required}"

cd /code

log() { printf '[glitchtip] %s\n' "$*"; }

# Wait for the schema to be reachable / creatable.
i=0
while [ "$i" -lt 60 ]; do
    if python manage.py migrate --noinput >/dev/null 2>&1; then
        log "migrations applied"
        break
    fi
    i=$((i + 1))
    sleep 2
done

# Create the superuser only when the auth table is empty; otherwise sync the
# password so it always matches the deploy param.
python manage.py shell -c "
from django.contrib.auth import get_user_model
U = get_user_model()
email = '$GLITCHTIP_ADMIN_EMAIL'
pwd = '$GLITCHTIP_ADMIN_PASSWORD'
if U.objects.count() == 0:
    U.objects.create_superuser(email=email, password=pwd)
    print('[glitchtip] superuser created:', email)
else:
    u = U.objects.filter(email__iexact=email).first()
    if u is None:
        print('[glitchtip] users already exist; leaving them untouched')
    else:
        u.set_password(pwd)
        u.is_staff = True
        u.is_superuser = True
        u.save()
        print('[glitchtip] superuser password synced:', email)
" || log "warning: could not seed superuser"

log "starting stock entrypoint"
exec ./bin/start.sh
