# VÉRITABLE GREMOIRE: vol. II d'Échos

## NPP WordPress - Docker Swarm Optimized

This repository contains a Docker Swarm optimized WordPress setup with Nginx FastCGI cache, designed for production deployment with high availability and scalability.

### Features

- **Docker Swarm Ready**: Optimized for deployment in Docker Swarm clusters
- **Health Checks**: Built-in health monitoring for Docker Swarm orchestration
- **Persistent Storage**: Support for `/var/www/html` and cache volumes
- **Centralized Logging**: Logs redirected to stdout/stderr for Docker logging drivers
- **Traefik Integration**: Pre-configured labels for Traefik reverse proxy
- **NPP Plugin**: Nginx FastCGI Cache Purge & Preload for WordPress
- **High Performance**: PHP-FPM with opcache, Redis object caching, and Nginx FastCGI cache

### Quick Start

#### Prerequisites

- Docker Swarm cluster initialized (`docker swarm init`)
- Traefik reverse proxy deployed with network named `traefik`
- External MariaDB database
- External Redis/Valkey cache (optional but recommended)

#### Deployment Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/purrmes/vol-ii-d-echos.git
   cd vol-ii-d-echos
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   nano .env
   ```

3. **Deploy to Docker Swarm**
   ```bash
   docker stack deploy -c stack.yml npp-wordpress
   ```

4. **Verify deployment**
   ```bash
   docker stack ps npp-wordpress
   docker service ls
   ```

### Configuration

#### Required Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WORDPRESS_DB_HOST` | Database host:port | `db:3306` |
| `WORDPRESS_DB_USER` | Database username | `wordpress` |
| `WORDPRESS_DB_PASSWORD` | Database password | *(required)* |
| `WORDPRESS_DB_NAME` | Database name | `wordpress` |
| `NPP_HTTP_HOST` | Your domain name | *(required)* |
| `NPP_UID` | PHP process owner UID | `18978` |
| `NPP_GID` | PHP process owner GID | `33749` |
| `NPP_USER` | PHP process owner username | `npp` |

See `.env.example` for complete configuration options.

### Health Checks

The WordPress container includes a built-in health check that verifies:
- PHP-FPM is running and configured correctly
- Database connectivity is established

Health check configuration:
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Start Period**: 60 seconds
- **Retries**: 3

### Persistent Volumes

The stack uses named volumes for persistent data:

- **wordpress_data**: WordPress files (`/var/www/html`)
- **nginx_cache**: Nginx FastCGI cache (tmpfs, 500MB)

For production, consider using:
- NFS volumes for shared storage across swarm nodes
- Volume plugins for cloud storage (AWS EFS, Azure Files, etc.)

### Log Management

All logs are redirected to stdout/stderr for centralized logging:
- PHP-FPM logs → stderr
- Nginx access logs → stdout
- Nginx error logs → stderr

View logs with:
```bash
docker service logs -f npp-wordpress_wordpress
docker service logs -f npp-wordpress_nginx
```

### Traefik Integration

The Nginx service includes Traefik labels for automatic:
- HTTPS configuration with Let's Encrypt
- HTTP to HTTPS redirection
- Load balancing across replicas

### Scaling

Scale services as needed:
```bash
# Scale Nginx
docker service scale npp-wordpress_nginx=3

# Scale WordPress (requires shared storage)
docker service scale npp-wordpress_wordpress=2
```

**Note**: When scaling WordPress, ensure persistent volumes are shared across nodes (NFS, cloud storage, etc.)

### Architecture

```
[Traefik] → [Nginx] → [PHP-FPM/WordPress] → [MariaDB]
                ↓                               ↓
         [FastCGI Cache]                  [Redis/Valkey]
```

### Development vs Production

- **Development**: Use `docker-compose.yml`
- **Production**: Use `stack.yml` for Docker Swarm

### Updating the Stack

```bash
# Update stack with new configuration
docker stack deploy -c stack.yml npp-wordpress

# Rolling update of a service
docker service update --image new-image:tag npp-wordpress_wordpress
```

### Troubleshooting

**Service won't start**
```bash
docker service ps npp-wordpress_wordpress --no-trunc
docker service logs npp-wordpress_wordpress
```

**Health check failing**
```bash
docker service ps npp-wordpress_wordpress
# Check the error message in the service state
```

**Database connection issues**
- Verify `WORDPRESS_DB_HOST`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, `WORDPRESS_DB_NAME`
- Ensure database is accessible from swarm nodes
- Check database service health

### Security Best Practices

1. **Use secrets for sensitive data**: Consider using Docker secrets instead of environment variables
2. **Update regularly**: Keep base images and WordPress updated
3. **Firewall rules**: Restrict access to swarm nodes
4. **HTTPS only**: Enforce HTTPS with Traefik
5. **Strong passwords**: Use strong, unique passwords for all services

### Documentation

- [WordPress Docker Image](https://hub.docker.com/_/wordpress)
- [NPP Plugin](https://wordpress.org/plugins/fastcgi-cache-purge-and-preload-nginx/)
- [Docker Swarm](https://docs.docker.com/engine/swarm/)
- [Traefik](https://doc.traefik.io/traefik/)

### Support

For issues and questions:
- NPP Plugin: https://github.com/psaux-it/nginx-fastcgi-cache-purge-and-preload
- Repository Issues: https://github.com/purrmes/vol-ii-d-echos/issues

### License

See [license.txt](license.txt) for details.

