# VÉRITABLE GREMOIRE: vol. II d'Échos

## NPP-Optimized WordPress with Nginx FastCGI Cache

This is a production-ready Docker Swarm deployment for WordPress with Nginx FastCGI caching, optimized for the [NPP (Nginx Cache Purge & Preload) WordPress plugin](https://wordpress.org/plugins/fastcgi-cache-purge-and-preload-nginx/).

## Architecture Overview

### Traefik Integration (Required)

**IMPORTANT:** This Nginx configuration is designed to run behind [Traefik](https://traefik.io/) reverse proxy and **requires** Traefik to be deployed in your Docker Swarm cluster.

**Traefik Responsibilities:**
- TLS/SSL certificate management and termination
- HTTP to HTTPS redirects
- External traffic routing and load balancing
- Service discovery via Docker labels

**Nginx Responsibilities:**
- Internal HTTP traffic handling (port 80 only)
- WordPress FastCGI caching
- PHP-FPM proxy and cache management
- Static file serving

### Network Flow

```
Internet → Traefik (TLS termination) → Nginx (HTTP:80) → PHP-FPM (WordPress)
                                     ↓
                              FastCGI Cache
```

### Key Features

- **FastCGI Caching:** High-performance page caching with the NPP plugin
- **Docker Swarm Ready:** Optimized for production deployment with health checks
- **Traefik Integration:** Automatic TLS certificate management
- **Centralized Logging:** All logs redirect to stdout/stderr for container logging
- **Environment Variable Configuration:** Flexible deployment configuration

## Quick Start

### Prerequisites

1. Docker Swarm cluster initialized
2. Traefik deployed with a network named `traefik`
3. External MariaDB and Valkey (Redis) instances

### Deployment

1. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   nano .env
   ```

2. **Update critical settings in `.env`:**
   - `NPP_HTTP_HOST`: Your domain name
   - `TRAEFIK_ROUTER_NAME`: Unique router name for Traefik
   - Database credentials
   - Valkey/Redis credentials

3. **Deploy the stack:**
   ```bash
   docker stack deploy -c docker-compose.yml npp
   ```

4. **Verify deployment:**
   ```bash
   docker stack ps npp
   docker service logs npp_nginx
   docker service logs npp_wordpress
   ```

## Configuration

### Environment Variables

The Nginx service accepts the following environment variables for Docker Swarm flexibility:

- `WORDPRESS_SERVICE`: Service name for WordPress/PHP-FPM (default: `wordpress`)
- `WORDPRESS_FPM_PORT`: PHP-FPM port (default: `9001`)
- `WORDPRESS_READY_PORT`: WordPress ready check port (default: `9999`)
- `MOUNT_DIR`: Nginx cache directory (default: `/var/cache/nginx`)
- `NPP_HTTP_HOST`: Your domain name (required)
- `NGINX_WEB_USER`: Nginx web server user (default: `nginx`)

### Traefik Labels

The `docker-compose.yml` includes Traefik labels for automatic service discovery:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(`${NPP_HTTP_HOST}`)"
  - "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=websecure"
  - "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true"
```

### Health Checks

Nginx includes a health check endpoint at `/health` for Docker Swarm monitoring:

```bash
curl http://localhost/health
# Returns: healthy
```

## Documentation

- **Production Deployment Guide:** See [PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md)
- **NPP Plugin:** https://github.com/psaux-it/nginx-fastcgi-cache-purge-and-preload
- **WordPress Plugin:** https://wordpress.org/plugins/fastcgi-cache-purge-and-preload-nginx/

## Support

For issues and support:
- NPP Plugin: https://github.com/psaux-it/nginx-fastcgi-cache-purge-and-preload
- WordPress Documentation: https://wordpress.org/support/

## License

See [license.txt](license.txt) for details.

