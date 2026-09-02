# Kopitech teaser — static site served by nginx
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="kopitech" \
      org.opencontainers.image.description="Kopitech teaser site (kopitech.my)" \
      org.opencontainers.image.source="https://github.com/nasyrulharon/kopitech"

RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/kopitech.conf
COPY site/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1
