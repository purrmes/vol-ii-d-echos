# Docker Swarm Deployment Guide

## Overview

This guide provides detailed instructions for deploying the NPP WordPress stack in a Docker Swarm environment with optimizations for production use.

## What's New in This Release

### 1. Dockerfile Optimizations

#### Health Checks
- **HEALTHCHECK directive** added to monitor PHP-FPM service health
- Custom `/healthcheck.sh` script validates PHP-FPM configuration
- Configurable intervals (30s), timeout (10s), start period (60s), and retries (3)

#### Environment Variables
- **ARG and ENV definitions** for database connection parameters
- Default values provided for `WORDPRESS_DB_HOST`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_NAME`
- Password must be provided at runtime (not in image) for security

#### Image Size Optimization
- `--no-install-recommends` flag for apt-get to reduce unnecessary packages
- Automatic cleanup of apt cache with `rm -rf /var/lib/apt/lists/*`
- Reduced final image size while maintaining all required functionality

### 2. Entrypoint Script Improvements

#### Dynamic Configuration
- Default values for database connection variables
- Runtime validation of all critical environment variables
- Better error messages for missing required variables

#### Required Environment Variables
The entrypoint now validates:
- `NPP_UID` - PHP process owner user ID
- `NPP_GID` - PHP process owner group ID
- `NPP_USER` - PHP process owner username
- `WORDPRESS_DB_HOST` - Database server address
- `WORDPRESS_DB_USER` - Database username
- `WORDPRESS_DB_PASSWORD` - Database password
- `WORDPRESS_DB_NAME` - Database name

### 3. Persistent Storage

#### Volume Configuration
- **wordpress_data**: Persistent WordPress files at `/var/www/html`
- **nginx_cache**: Tmpfs volume for FastCGI cache (500MB)

#### Production Recommendations
For production deployments, consider:
- **NFS volumes** for shared storage across swarm nodes
- **Cloud storage plugins** (AWS EFS, Azure Files, GCP Filestore)
- **Local volumes** with proper backup strategies

### 4. Log Management

#### Centralized Logging
All logs are directed to stdout/stderr:
- **PHP-FPM logs** → stderr (via `daemonize = no` in zz-docker.conf)
- **Nginx access logs** → stdout
- **Nginx error logs** → stderr

#### Viewing Logs
```bash
# View WordPress service logs
docker service logs -f npp-wordpress_wordpress

# View Nginx service logs
docker service logs -f npp-wordpress_nginx

# View last 100 lines
docker service logs --tail 100 npp-wordpress_wordpress
```

### 5. Docker Swarm Stack File (stack.yml)

#### Key Features

**Service Configuration:**
- Pre-configured for Traefik reverse proxy integration
- Health checks for both WordPress and Nginx services
- Resource limits and reservations
- Update and rollback policies
- Placement constraints

**Traefik Labels:**
- Automatic HTTPS with Let's Encrypt
- HTTP to HTTPS redirection
- Load balancing across replicas
- Custom router names via environment variables

**Network Configuration:**
- Overlay network for service communication
- External Traefik network for ingress
- Attachable network for debugging

## Deployment Instructions

### Prerequisites

1. **Initialize Docker Swarm** (if not already done)
   ```bash
   docker swarm init
   ```

2. **Deploy Traefik** reverse proxy
   ```bash
   # Create external network for Traefik
   docker network create --driver overlay traefik
   
   # Deploy Traefik (use your own Traefik stack file)
   docker stack deploy -c traefik-stack.yml traefik
   ```

3. **Set up external services**
   - MariaDB database
   - Valkey/Redis cache (optional but recommended)

### Deployment Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/purrmes/vol-ii-d-echos.git
   cd vol-ii-d-echos
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   nano .env
   ```

   **Critical settings to update:**
   ```bash
   # Database configuration
   export WORDPRESS_DB_HOST=your-mariadb-hostname:3306
   export WORDPRESS_DB_USER=your_db_user
   export WORDPRESS_DB_PASSWORD=your_secure_password
   export WORDPRESS_DB_NAME=your_database_name
   
   # Domain configuration
   export NPP_HTTP_HOST=your-domain.com
   
   # Traefik configuration
   export TRAEFIK_ROUTER_NAME=your-site-name
   ```

3. **Build and push images** (if needed)
   ```bash
   # Build images
   docker build -f wordpress/Dockerfile -t your-registry/wordpress:latest .
   docker build -f nginx/Dockerfile -t your-registry/nginx:latest .
   
   # Push to registry
   docker push your-registry/wordpress:latest
   docker push your-registry/nginx:latest
   
   # Update stack.yml with your image names
   ```

4. **Deploy the stack**
   ```bash
   docker stack deploy -c stack.yml npp-wordpress
   ```

5. **Verify deployment**
   ```bash
   # Check stack status
   docker stack ps npp-wordpress
   
   # Check services
   docker service ls
   
   # Check logs
   docker service logs npp-wordpress_wordpress
   docker service logs npp-wordpress_nginx
   ```

6. **Access your site**
   Navigate to `https://your-domain.com`

## Health Monitoring

### Health Check Configuration

The WordPress service includes a health check that runs every 30 seconds:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh
```

### Monitoring Health Status

```bash
# View service health
docker service ps npp-wordpress_wordpress

# Detailed service inspection
docker service inspect npp-wordpress_wordpress
```

### Health Check Script

The `/healthcheck.sh` script verifies:
1. PHP-FPM configuration is valid (`php-fpm -t`)
2. Returns exit code 0 if healthy, 1 if unhealthy

## Scaling

### Scaling Nginx
Nginx can be scaled horizontally without issues:
```bash
docker service scale npp-wordpress_nginx=3
```

### Scaling WordPress
WordPress can be scaled if using shared storage:
```bash
# Requires NFS or cloud storage for /var/www/html
docker service scale npp-wordpress_wordpress=2
```

**Important:** Local volumes don't work with multiple replicas. Use NFS or cloud storage.

## Updating Services

### Rolling Updates
```bash
# Update with new image
docker service update --image your-registry/wordpress:v2 npp-wordpress_wordpress

# Update environment variable
docker service update --env-add NEW_VAR=value npp-wordpress_wordpress
```

### Update Configuration
```bash
# Edit stack.yml with changes
nano stack.yml

# Redeploy stack (Docker will update only changed services)
docker stack deploy -c stack.yml npp-wordpress
```

## Troubleshooting

### Service Won't Start

```bash
# Check service tasks
docker service ps npp-wordpress_wordpress --no-trunc

# Check logs
docker service logs --tail 100 npp-wordpress_wordpress
```

### Health Check Failing

```bash
# Check health check logs
docker service ps npp-wordpress_wordpress

# Manually run health check
docker exec $(docker ps -q -f name=npp-wordpress_wordpress) /healthcheck.sh
echo $?  # Should be 0 if healthy
```

### Database Connection Issues

```bash
# Verify database is accessible from swarm nodes
docker run --rm -it mariadb:latest mysql -h YOUR_DB_HOST -u YOUR_DB_USER -p

# Check environment variables
docker service inspect npp-wordpress_wordpress | grep -A 20 Env
```

### Volume Issues

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect npp-wordpress_wordpress_data

# Check volume mounts
docker service inspect npp-wordpress_wordpress | grep -A 10 Mounts
```

## Security Best Practices

1. **Use Docker Secrets** for sensitive data (recommended over environment variables)
   ```bash
   # Create secret
   echo "your_password" | docker secret create db_password -
   
   # Reference in stack.yml
   secrets:
     - db_password
   ```

2. **Regular Updates**
   - Keep base images updated
   - Update WordPress core and plugins regularly
   - Monitor security advisories

3. **Network Isolation**
   - Use overlay networks for service communication
   - Restrict external access to necessary services only
   - Use Traefik for TLS termination

4. **Resource Limits**
   - Set appropriate CPU and memory limits
   - Monitor resource usage
   - Adjust based on load

5. **Backup Strategy**
   - Regular database backups
   - WordPress files backups
   - Test restore procedures

## Performance Optimization

### Resource Allocation
```yaml
resources:
  limits:
    cpus: "2.0"      # Increase for high traffic
    memory: "4GB"    # Increase for large sites
  reservations:
    cpus: "1.0"
    memory: "2GB"
```

### Caching Strategy
- **Nginx FastCGI Cache**: 500MB tmpfs (adjust as needed)
- **Redis Object Cache**: External Valkey/Redis
- **Opcache**: Pre-configured in PHP settings

### Monitoring
Consider adding:
- Prometheus + Grafana for metrics
- ELK stack for log aggregation
- Health check monitoring

## Support and Documentation

- **Repository**: https://github.com/purrmes/vol-ii-d-echos
- **NPP Plugin**: https://github.com/psaux-it/nginx-fastcgi-cache-purge-and-preload
- **Docker Swarm**: https://docs.docker.com/engine/swarm/
- **Traefik**: https://doc.traefik.io/traefik/

## License

See [license.txt](license.txt) for details.
