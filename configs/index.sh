#!/usr/bin/bash

set -e

# Define variables
SSH_KEY="../infra/id_rsa"
MONITORING_SERVER_IP=13.40.28.32
APP_SERVER_IP=13.40.25.142
DATABASE_SERVER_IP=172.20.10.118

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required files exist
if [ ! -f "$SSH_KEY" ]; then
    log_error "SSH private key (id_rsa) not found!"
    log_info "Provision the infrastructure first"
    exit 1
fi

# Configure monitoring server
log_info "Configuring monitoring server..."
chmod 740 monitor.sh
scp -o StrictHostKeyChecking=no -i $SSH_KEY $SSH_KEY monitor.sh prometheus.yml alert.rules.yml alertmanager.yml ubuntu@"$MONITORING_SERVER_IP":/tmp
ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@"$MONITORING_SERVER_IP" "bash /tmp/monitor.sh"
log_success "Monitoring server configured successfully"


# Configure application server
log_info "Configuring application server..."
chmod 740 app.sh
scp -o StrictHostKeyChecking=no -i $SSH_KEY $SSH_KEY app.sh ubuntu@"$APP_SERVER_IP":/tmp
ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@"$APP_SERVER_IP" "bash /tmp/app.sh"
log_success "Application server configured successfully"


# Configure database server
log_info "Configuring database server..."
chmod 740 db.sh
scp -o StrictHostKeyChecking=no -i $SSH_KEY db.sh ubuntu@"$APP_SERVER_IP":/tmp
ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@"$APP_SERVER_IP" "scp -o StrictHostKeyChecking=no -i /tmp/id_rsa /tmp/db.sh ubuntu@"$DATABASE_SERVER_IP":/tmp && ssh -o StrictHostKeyChecking=no -i /tmp/id_rsa ubuntu@"$DATABASE_SERVER_IP" "bash /tmp/db.sh""
log_success "Database server configured successfully"

echo "################################################################################"
echo "Monitoring Server IP: $MONITORING_SERVER_IP"
echo "Application Server IP: $APP_SERVER_IP"
echo "Database Server IP: $DATABASE_SERVER_IP"

echo -e "${GREEN}🎉 All servers have been configured successfully! 🎉${NC}"
echo "################################################################################"