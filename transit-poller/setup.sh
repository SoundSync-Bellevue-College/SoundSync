#!/bin/bash
set -e

echo "=== Transit Poller Setup for Ubuntu 24 ==="
echo ""

# Check if running on Ubuntu 24
if ! grep -q "24.04\|24.10" /etc/os-release 2>/dev/null; then
    echo "Warning: This script is tested on Ubuntu 24. Your system may differ."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "[1/5] Updating package lists..."
sudo apt-get update -qq

echo "[2/5] Installing Python 3.12 and pip..."
sudo apt-get install -y -qq python3.12 python3.12-venv python3-pip

echo "[3/5] Installing PostgreSQL client libraries..."
sudo apt-get install -y -qq libpq-dev postgresql postgresql-contrib

echo "[4/5] Starting PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "[5/5] Creating Python virtual environment..."
if [ ! -d ".venv" ]; then
    python3.12 -m venv .venv
    echo "Virtual environment created at .venv/"
else
    echo "Virtual environment already exists"
fi

echo "[6/6] Installing Python dependencies..."
.venv/bin/pip install --quiet --upgrade pip
.venv/bin/pip install --quiet psycopg2-binary requests python-dotenv

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo ""
echo "1. Create PostgreSQL database and user (run as sudo):"
echo "   sudo -u postgres psql -c \"CREATE USER soundsync WITH PASSWORD 'your_password';\""
echo "   sudo -u postgres psql -c \"CREATE DATABASE soundsync OWNER soundsync;\""
echo ""
echo "2. Create .env file with your configuration:"
echo "   cat > .env << EOF"
echo "OBA_API_KEY=b34cc383-9c66-420b-ad93-2c070bb0e4d9"
echo "DB_HOST=localhost"
echo "DB_PORT=5432"
echo "DB_NAME=soundsync"
echo "DB_USER=postgres"
echo "DB_PASSWORD=postgres"
echo "EOF"
echo ""
echo "3. Activate the virtual environment and run the poller:"
echo "   source .venv/bin/activate"
echo "   python3 poller.py"
echo ""
echo "4. In another terminal, export data:"
echo "   source .venv/bin/activate"
echo "   python3 export_data.py --date $(date +%Y-%m-%d)"
