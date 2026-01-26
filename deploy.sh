#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== WG-Easy Deployment Script ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (sudo ./deploy.sh)${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker not found. Installing...${NC}"
    curl -sSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}Docker installed successfully${NC}"
fi

# Check if .env file exists
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo -e "${YELLOW}No .env file found. Creating from .env.example...${NC}"
        cp .env.example .env
        echo -e "${RED}Please edit .env file with your settings:${NC}"
        echo "  - INIT_HOST: Your server's public IP or domain"
        echo "  - INIT_PASSWORD: Admin password for web UI"
        echo ""
        echo "Then run this script again."
        exit 1
    else
        echo -e "${RED}No .env or .env.example file found!${NC}"
        exit 1
    fi
fi

# Source .env to check required variables
source .env

if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "vpn.example.com" ]; then
    echo -e "${RED}Error: DOMAIN is not set or still has default value${NC}"
    echo "Please edit .env and set DOMAIN to your server's domain name"
    exit 1
fi

if [ -z "$ACME_EMAIL" ] || [ "$ACME_EMAIL" = "admin@example.com" ]; then
    echo -e "${RED}Error: ACME_EMAIL is not set or still has default value${NC}"
    echo "Please edit .env and set your email for Let's Encrypt"
    exit 1
fi

if [ -z "$INIT_PASSWORD" ] || [ "$INIT_PASSWORD" = "your-secure-password-here" ]; then
    echo -e "${RED}Error: INIT_PASSWORD is not set or still has default value${NC}"
    echo "Please edit .env and set a secure password"
    exit 1
fi

# Open firewall ports if ufw is installed
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Configuring firewall (ufw)...${NC}"
    ufw allow 80/tcp comment "HTTP (for Let's Encrypt)"
    ufw allow 443/tcp comment "HTTPS"
    ufw allow ${WG_PORT:-51820}/udp comment "WireGuard"
    echo -e "${GREEN}Firewall configured${NC}"
fi

# Start the service
echo -e "${YELLOW}Starting WG-Easy...${NC}"
docker compose up -d

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "WireGuard VPN is now running!"
echo ""
echo "  Web UI:     https://${DOMAIN}"
echo "  Username:   ${INIT_USERNAME:-admin}"
echo "  Password:   (as set in .env)"
echo ""
echo "  WireGuard:  ${DOMAIN}:${WG_PORT:-51820}/udp"
echo ""
echo -e "${YELLOW}Note:${NC} SSL certificate will be issued automatically."
echo "First request may take a few seconds while certificate is obtained."
echo ""
echo -e "${YELLOW}Commands:${NC}"
echo "  View logs:    docker compose logs -f"
echo "  Stop:         docker compose down"
echo "  Restart:      docker compose up -d"
