#!/bin/bash
# =============================================================
# VM2 — Serveur Web (Zone DMZ)
# mbenendiaye657 — projet-fin-module
# Nginx (reverse proxy) + Node.js (application)
# IP : 192.168.100.10
# Passerelle par défaut : 192.168.100.1 (VM1)
# =============================================================

echo "=== Configuration du serveur web ==="

# 1. Configurer la passerelle par défaut vers VM1
sudo ip route add default via 192.168.100.1 || true
echo "Route par défaut -> 192.168.100.1 (passerelle)"

# 2. Mise à jour des paquets
sudo apt-get update -y -q
echo "Paquets mis à jour"

# 3. Installation de Nginx
sudo apt-get install -y nginx -q
sudo systemctl enable nginx
sudo systemctl start nginx
echo "Nginx installé et démarré"

# 4. Installation de Node.js 18 et npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - -q
sudo apt-get install -y nodejs -q
echo "Node.js $(node -v) installé"

# 5. Installation de Git
sudo apt-get install -y git -q

# 6. Créer le dossier de l'application
sudo mkdir -p /opt/app
sudo chown vagrant:vagrant /opt/app

# 7. Copier les fichiers de l'application depuis /vagrant (dossier partagé)
cp /vagrant/app/server.js /opt/app/server.js
cp /vagrant/app/package.json /opt/app/package.json

# 8. Installer les dépendances Node.js
cd /opt/app && npm install -q
echo "Dépendances Node.js installées"

# 9. Configurer Nginx comme reverse proxy vers Node.js (port 3000)
sudo tee /etc/nginx/sites-available/mbened-dev > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://127.0.0.1:3000/health;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/mbened-dev /etc/nginx/sites-enabled/mbened-dev
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
echo "Nginx configuré en reverse proxy"

# 10. Créer le service systemd pour Node.js
sudo tee /etc/systemd/system/mbened-app.service > /dev/null << 'EOF'
[Unit]
Description=mbened-dev Node.js App
After=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/opt/app
Environment=DB_HOST=192.168.10.10
Environment=DB_USER=appuser
Environment=DB_PASSWORD=apppassword123
Environment=DB_NAME=appdb
Environment=PORT=3000
ExecStart=/usr/bin/node /opt/app/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mbened-app
sudo systemctl start mbened-app
echo "Service Node.js démarré"

# 11. Vérification
echo ""
echo "=== État des services ==="
sudo systemctl status nginx --no-pager -l
sudo systemctl status mbened-app --no-pager -l
echo ""
echo "=== Test local ==="
sleep 3
curl -s http://localhost || echo "App pas encore prête"
echo ""
echo "=== VM2 Serveur Web configuré avec succès ==="
echo "=== Accessible sur http://192.168.100.10 ==="
