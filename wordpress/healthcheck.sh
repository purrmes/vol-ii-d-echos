#!/usr/bin/env bash
#
# Copyright (C) 2024 Hasan CALISIR <hasan.calisir@psauxit.com>
# Distributed under the GNU General Public License, version 2.0.
#
# Health check script for Docker Swarm
# This script verifies that PHP-FPM is running correctly

set -e

# Check if PHP-FPM configuration is valid
php-fpm -t > /dev/null 2>&1 || exit 1

# Check if PHP-FPM is responsive by verifying the socket/port is listening
# PHP-FPM typically listens on port 9000 or a Unix socket
if [ -S /run/php-fpm/www.sock ]; then
    # Unix socket exists and is accessible
    true
elif netstat -tln 2>/dev/null | grep -q ':9000 ' || ss -tln 2>/dev/null | grep -q ':9000 '; then
    # Check if listening on port 9000
    true
else
    # If neither socket nor port is available, PHP-FPM might not be running
    pgrep php-fpm > /dev/null 2>&1 || exit 1
fi

# If we get here, all checks passed
exit 0
