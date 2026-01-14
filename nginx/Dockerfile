# Dockerfile for NPP-Optimized WordPress Setup                                     #
# ----------------------------------------------------------------------------     #
# Author: [Hasan ÇALIŞIR]                                                          #
# Purpose: Full-stack Dockerized environment for NPP WordPress plugin, including   #
#          WordPress, PHP-FPM, Nginx, MySQL, WP-CLI, and necessary PHP extensions. #
# ----------------------------------------------------------------------------     #

# Here the magic, the rest of it is ordinary
FROM nginx:1.29.1-bookworm

# Install necessary packages
RUN apt-get update && apt-get install -y \
    netcat-traditional \
    procps \
    curl

# Define build arguments and environment variables for Docker Swarm flexibility
ARG WORDPRESS_SERVICE=wordpress
ARG WORDPRESS_FPM_PORT=9001
ARG WORDPRESS_READY_PORT=9999
ARG MOUNT_DIR=/var/cache/nginx

ENV WORDPRESS_SERVICE=${WORDPRESS_SERVICE} \
    WORDPRESS_FPM_PORT=${WORDPRESS_FPM_PORT} \
    WORDPRESS_READY_PORT=${WORDPRESS_READY_PORT} \
    MOUNT_DIR=${MOUNT_DIR}

# Copy the entrypoint script into the container
COPY nginx/entrypoint-nginx.sh /entrypoint-nginx.sh

# Make sure the entrypoint script is executable
RUN chmod +x /entrypoint-nginx.sh

# Add healthcheck for Docker Swarm monitoring
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# CMD
CMD ["/entrypoint-nginx.sh", "nginx", "-g", "daemon off;"]
