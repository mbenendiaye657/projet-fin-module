#!/bin/bash
# =============================================================
# VM3 — Serveur Base de Données (Réseau LAN)
# mbenendiaye657 — projet-fin-module
# MySQL 8.0
# IP : 192.168.10.10
# Passerelle par défaut : 192.168.10.1 (VM1)
# =============================================================

echo "=== Configuration du serveur base de données ==="

# 1. Configurer la passerelle par défaut vers VM1
sudo ip route add default via 192.168.10.1 || true
echo "Route par défaut -> 192.168.10.1 (passerelle)"

# 2. Mise à jour des paquets
sudo apt-get update -y -q
echo "Paquets mis à jour"

# 3. Installation de MySQL Server
sudo apt-get install -y mysql-server -q
sudo systemctl enable mysql
sudo systemctl start mysql
echo "MySQL installé et démarré"

# 4. Sécurisation de MySQL (équivalent mysql_secure_installation)
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"
echo "MySQL sécurisé"

# 5. Création de la base de données
sudo mysql -e "CREATE DATABASE IF NOT EXISTS appdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
echo "Base de données 'appdb' créée"

# 6. Création de l'utilisateur pour VM2 (serveur web)
# Accès autorisé depuis 192.168.100.10 (VM2 Web dans la DMZ)
sudo mysql -e "CREATE USER IF NOT EXISTS 'appuser'@'192.168.100.10' IDENTIFIED BY 'apppassword123';"
sudo mysql -e "GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'192.168.100.10';"
sudo mysql -e "FLUSH PRIVILEGES;"
echo "Utilisateur 'appuser' créé avec accès depuis 192.168.100.10"

# 7. Créer une table de test
sudo mysql appdb -e "
CREATE TABLE IF NOT EXISTS messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  contenu VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO messages (contenu) VALUES ('Bienvenue sur mbened-dev !');
INSERT INTO messages (contenu) VALUES ('Architecture 3-tiers fonctionnelle');
"
echo "Table de test créée avec données"

# 8. Configurer MySQL pour écouter sur toutes les interfaces
# (Nécessaire pour que VM2 puisse se connecter)
sudo sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql
echo "MySQL configuré pour écouter sur 0.0.0.0:3306"

# 9. Vérification
echo ""
echo "=== État de MySQL ==="
sudo systemctl status mysql --no-pager -l
echo ""
echo "=== MySQL en écoute ==="
sudo ss -tlnp | grep 3306
echo ""
echo "=== Bases de données ==="
sudo mysql -e "SHOW DATABASES;"
echo ""
echo "=== Utilisateurs ==="
sudo mysql -e "SELECT User, Host FROM mysql.user WHERE User='appuser';"
echo ""
echo "=== VM3 Serveur DB configuré avec succès ==="
echo "=== MySQL accessible sur 192.168.10.10:3306 ==="
