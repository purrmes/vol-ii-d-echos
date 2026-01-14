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

# If we get here, all checks passed
exit 0
