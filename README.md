# GlitchTip (LazyCat LPK)

Open-source error tracking (a Sentry-compatible alternative).

- Upstream: https://github.com/burke-software/GlitchTip
- Image: `glitchtip/glitchtip:6.2.6` (Docker Hub, mirror mode, digest-matched)
- License: MIT (full text in `content/licenses/LICENSE`)
- Containers: GlitchTip + PostgreSQL 16 + Redis 7

## Notes

- The image lives on Docker Hub, **not** GHCR — `ghcr.io/glitchtip/*` returns 403.
  A 403 from one registry does not mean no image exists; check Docker Hub too.
- Working dir is `/code` (Django, Python 3.14), so admin seeding goes through
  `python manage.py`. Upstream documents no bootstrap step, so `content/create-admin.sh`
  wraps the entrypoint: migrate (idempotent) → create or password-sync the superuser →
  exec the stock `./bin/start.sh`.
- Required env: `SECRET_KEY`, `DATABASE_URL`, `REDIS_URL`, `EMAIL_URL`, `DEFAULT_FROM_EMAIL`
  (per upstream `app-platform.yaml`). Secrets come from platform stable secrets; admin
  email/password from deploy params.
- `EMAIL_URL=consolemail://` since no mail service is available — use webhooks for alerts.
- Not yet verified on a real device.
