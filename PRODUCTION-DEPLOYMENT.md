# Production Deployment Guide

## Pre-Deployment Checklist

### 1. Security Configuration

**Update all passwords and secrets in `.env`:**
- [ ] `DB_PASSWORD` - Set the MariaDB password (passed from project-level environment)
- [ ] `WORDPRESS_ADMIN_PASSWORD` - Use a strong password
- [ ] `WORDPRESS_ADMIN_USER` - Change from default 'npp'
- [ ] `WORDPRESS_ADMIN_EMAIL` - Set to your production email

**Note:** The database has been deployed separately as an external MariaDB instance:
- Host: `livre-des-echos-mariadb-zq4m2z`
- Database: `db_vol_i`
- User: `db_user`
- Password: Provided via `DB_PASSWORD` environment variable

### 2. Domain Configuration

**Update domain settings in `.env`:**
- [ ] `NPP_HTTP_HOST` - Set to your actual domain (e.g., example.com)
- [ ] `WORDPRESS_SITE_URL_` - Set to your full site URL (e.g., https://example.com)
- [ ] `WORDPRESS_SITE_TITLE_` - Set your site title

### 3. SSL Certificates

**Configure SSL certificates:**
- [ ] Place your SSL certificates in the `./ssl` directory
- [ ] Ensure proper certificate file naming
- [ ] Verify nginx SSL configuration in `./nginx/default.conf`

### 4. Resource Limits

**Review and adjust resource limits in `docker-compose.yml` based on your server:**
- WordPress container: Currently set to 2GB RAM, 1 CPU
- Nginx container: Currently set to 1.5GB RAM, 1 CPU

**Note:** Database resources are managed separately in the external MariaDB deployment.

### 5. Database Configuration

**Review MySQL configuration:**
- [ ] Check `./mysql/50-npp-server.cnf` for production settings
- [ ] Ensure proper character set and collation
- [ ] Review buffer sizes and cache settings

### 5. PHP Configuration

**Review PHP settings in `./php/npp.ini`:**
- [ ] Verify `display_errors = Off` for production
- [ ] Adjust `memory_limit` based on your needs
- [ ] Review file upload limits
- [ ] Verify opcache settings are optimized

### 6. Nginx Configuration

**Review Nginx settings:**
- [ ] Verify cache settings in `./nginx/default.conf`
- [ ] Check fastcgi cache configuration
- [ ] Ensure proper security headers
- [ ] Review rate limiting settings

## Deployment Steps

### 1. Initial Setup

```bash
# Clone or copy the project to your server
# Navigate to the project directory
cd /path/to/vol-ii-d-echos

# Ensure DB_PASSWORD environment variable is set (from project-level .env)
# This should be provided by your deployment platform
echo $DB_PASSWORD  # Verify it's set

# Edit .env file with production values if needed
nano .env
```

### 2. Build Images

```bash
# Build Docker images
docker-compose build
```

### 3. Start Services

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Manual WordPress Installation

Since automatic WordPress installation has been removed for production, you need to manually set up WordPress:

**Option A: Via WP-CLI (recommended)**
```bash
# Access the WordPress container
docker exec -it wordpress-fpm bash

# Install WordPress core
su -m -c "wp core install \
  --url='https://yourdomain.com' \
  --title='Your Site Title' \
  --admin_user='youradmin' \
  --admin_password='yourpassword' \
  --admin_email='admin@yourdomain.com'" npp

# Set permalink structure
su -m -c "wp rewrite structure '/%postname%/' --hard" npp

# Exit container
exit
```

**Option B: Via Web Browser**
1. Navigate to your domain in a web browser
2. Follow the WordPress installation wizard
3. Configure permalinks in Settings → Permalinks

### 5. Install Plugins

```bash
# Access the WordPress container
docker exec -it wordpress-fpm bash

# Install required NPP plugin
su -m -c "wp plugin install fastcgi-cache-purge-and-preload-nginx --activate" npp

# Install any other required plugins
su -m -c "wp plugin install [plugin-name] --activate" npp

# Exit container
exit
```

### 6. Post-Deployment Verification
external MariaDB 
- [ ] Verify site is accessible via HTTPS
- [ ] Test WordPress admin login
- [ ] Check nginx cache is working
- [ ] Verify database connectivity
- [ ] Test file uploads
- [ ] Review container logs for errors

## Monitoring and Maintenance

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f wordpress
docker-compose logs -f nginx
```

### Update Images
```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d --force-recreate
```

### Backup

**Database Backup:**
```bash
# Connect to external MariaDB and create backup
mysqldump -h livre-des-echos-mariadb-zq4m2z -u db_user -p db_vol_i > backup-$(date +%Y%m%d).sql
```

**WordPress Files Backup:**
```bash
tar -czf wordpress-files-$(date +%Y%m%d).tar.gz ./wordpress
```

## Security Best Practices

1. **Keep everything updated**: Regularly update Docker images, WordPress core, and plugins
2. **Use strong passwords**: Never use default or weak passwords in production
3. **Enable SSL/TLS**: Always use HTTPS with valid SSL certificates
4. **Regular backups**: Implement automated backup solutions
5. **Monitor logs**: Regularly review container logs for suspicious activity
6. **Firewall rules**: Configure firewall to only allow necessary ports
7. **Limit access**: Use VPN or IP whitelisting for admin access if possible

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs [service-name]

# Check container status
docker-compose ps

# Restart service
docker-compose restart [service-name]
```

### Database connection issues
- Verify database credentials in `.env`
- Ensure database container is running
- Check database logs: `docker-compose logs db`

### Permission issues
- Verify NPP_UID and NPP_GID match your host user
- Check file ownership: `docker exec wordpress-fpm ls -la /var/www/html`

## Support

For issues and support:
- NPP Plugin: https://github.com/psaux-it/nginx-fastcgi-cache-purge-and-preload
- WordPress Documentation: https://wordpress.org/support/
