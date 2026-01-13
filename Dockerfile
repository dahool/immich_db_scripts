# Imagen base con Docker CLI
FROM docker:25.0.3-cli

# Instalar utilidades necesarias (psql, coreutils para sha256sum)
RUN apk add --no-cache bash coreutils

# Copiar script y SQLs
WORKDIR /app
COPY migrate.sh /app/migrate.sh
COPY sql /app/sql

RUN chmod +x /app/migrate.sh

ENTRYPOINT ["/app/migrate.sh"]
