FROM wordpress:php8.5-fpm

# Set some ugly stuff
ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# Set package URL's
ENV WP_CLI_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" \
    PHP_EXT_URL="https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions"

# Set PHP extensions
ENV PHP_EXTENSIONS="bz2 calendar ctype curl dom iconv json mbstring pdo_pgsql readline simplexml \
    soap sockets sodium xml xsl openssl exif zip intl event memcached yaml \
    xdebug apcu zlib session redis uuid brotli http mailparse ssh2 xattr \
    xdiff filter igbinary opcache timezonedb bcmath shmop pcre geos"

# Install dependencies
# Build time dependencies will purged soon
RUN apt-get update && apt-get install -y \
    # Install runtime dependencies for NPP core
    procps \
    gawk \
    grep \
    sed \
    coreutils \
    wget \
    cpulimit \
    # Install dependencies for service health checks
    mariadb-client \
    netcat-traditional \
    iputils-ping \
    # Install common dependencies
    curl \
    # Install dev deploy dependencies
    git \
    dos2unix

# Get WP-CLI
RUN curl -LO ${WP_CLI_URL} \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Install PHP extensions
ADD --chmod=0755 ${PHP_EXT_URL} /usr/local/bin/
RUN install-php-extensions ${PHP_EXTENSIONS}

# Copy the scripts into the container
COPY wordpress/entrypoint-wp.sh /entrypoint-wp.sh
COPY wordpress/wp-post.sh /scripts/wp-post.sh

# Make sure scripts are executable
RUN chmod +x /entrypoint-wp.sh
RUN chmod +x /scripts/wp-post.sh

# CMD
CMD ["/entrypoint-wp.sh", "php-fpm"]
