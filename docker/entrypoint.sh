#!/bin/bash
set -e

echo "Starting Horilla CRM..."

# Wait for PostgreSQL to be ready (with timeout)
echo "Waiting for PostgreSQL..."
MAX_TRIES=30
COUNT=0
while ! nc -z db 5432; do
  COUNT=$((COUNT + 1))
  if [ "$COUNT" -ge "$MAX_TRIES" ]; then
    echo "ERROR: PostgreSQL not available after $MAX_TRIES attempts"
    exit 1
  fi
  sleep 1
done
echo "PostgreSQL is ready!"

# Named volumes are often root-owned; appuser must be able to write media.
mkdir -p /app/media /app/staticfiles
if [ -w /app/media ] && [ -w /app/staticfiles ]; then
  :
else
  echo "WARNING: /app/media or /app/staticfiles is not writable by $(id -un)"
fi

# Run migrations
python manage.py migrate --noinput

# Collect static files
python manage.py collectstatic --noinput

echo "Starting server..."
exec "$@"
