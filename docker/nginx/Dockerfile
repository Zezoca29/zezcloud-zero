FROM nginx:1.27-alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom configs
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/     /etc/nginx/conf.d/

# Generate self-signed SSL cert (replaced by real cert via Cloudflare/ACM in prod)
RUN apk add --no-cache curl openssl && \
    mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out    /etc/nginx/ssl/cert.pem \
        -subj   "/CN=localhost/O=ZezCloud/C=BR"

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
