FROM nginx:1.27-alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom configs
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/     /etc/nginx/conf.d/

# Health check endpoint support
RUN apk add --no-cache curl

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
