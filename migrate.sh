#!/bin/bash
set -e

DBOWNER="${DBOWNER:-postgres}"
DBNAME="${DBNAME:-immich}"
CONTAINER="${PGCONTAINER:-immich_postgres}"

docker exec -i $CONTAINER psql -U $DBOWNER -d $DBNAME <<'EOF'
CREATE TABLE IF NOT EXISTS public.local_migration (
    id SERIAL PRIMARY KEY,
    script_name TEXT NOT NULL,
    script_hash TEXT NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
EOF

for file in "/app/sql/*.sql"; do
  [ -e "$file" ] || continue

  script_name=$(basename "$file")
  script_hash=$(sha256sum "$file" | awk '{print $1}')

  echo "Procesando $script_name..."

  exists=$(docker exec -i $CONTAINER psql -U $DBOWNER -d $DBNAME -t -c \
    "SELECT 1 FROM public.local_migration WHERE script_name = '$script_name' AND script_hash = '$script_hash' LIMIT 1;")

  if [[ -z "$exists" ]]; then
    echo "Ejecutando $script_name..."
    docker exec -i $CONTAINER psql -U $DBOWNER -d $DBNAME < "$file"

    echo "Registrando migración..."
    docker exec -i $CONTAINER psql -U $DBOWNER -d $DBNAME -c \
      "INSERT INTO public.local_migration (script_name, script_hash) VALUES ('$script_name', '$script_hash');"
  else
    echo "Ya aplicado: $script_name"
  fi
done
