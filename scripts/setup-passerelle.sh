#!/bin/bash
# =============================================================
# VM1 — Passerelle / Firewall
# mbenendiaye657 — projet-fin-module
# Architecture 3-tiers : Internet <-> DMZ <-> LAN
# =============================================================

echo "=== Configuration de la passerelle ==="

# 1. Nettoyage des anciennes règles iptables
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -P FORWARD DROP
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT

# 2. Activation du forwarding IPv4
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
echo "Forwarding IPv4 activé"

# 3. NAT — Masquerade pour l'accès Internet
# Toutes les VMs passent par eth0 (NAT Vagrant) pour Internet
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo "NAT MASQUERADE configuré sur eth0"

# 4. RÈGLE : DB (192.168.10.10) peut accéder au WEB et à Internet
# La DB doit pouvoir joindre le serveur web et faire des mises à jour
sudo iptables -A FORWARD -s 192.168.10.10 -j ACCEPT
echo "Règle : DB -> WEB + Internet AUTORISÉ"

# 5. RÈGLE : WEB (192.168.100.10) peut accéder à Internet uniquement
# Le serveur web peut faire des apt-get, npm install etc.
sudo iptables -A FORWARD -s 192.168.100.10 -o eth0 -j ACCEPT
echo "Règle : WEB -> Internet AUTORISÉ"

# 6. RÈGLE : Internet peut accéder au WEB (port 80 et 443)
sudo iptables -A FORWARD -p tcp -d 192.168.100.10 --dport 80  -j ACCEPT
sudo iptables -A FORWARD -p tcp -d 192.168.100.10 --dport 443 -j ACCEPT
sudo iptables -A FORWARD -p icmp -d 192.168.100.10 -j ACCEPT
echo "Règle : Internet -> WEB port 80/443 AUTORISÉ"

# 7. RÈGLE : WEB -> DB INTERDIT (sécurité — DMZ ne peut pas atteindre LAN)
sudo iptables -A FORWARD -s 192.168.100.10 -d 192.168.10.10 -j REJECT
echo "Règle : WEB -> DB BLOQUÉ (REJECT)"

# 8. RÈGLE : Internet -> DB INTERDIT (déjà couvert par POLICY DROP)
sudo iptables -A FORWARD -d 192.168.10.10 -j REJECT
echo "Règle : Internet -> DB BLOQUÉ"

# 9. Autoriser les connexions déjà établies (retour de trafic)
sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
echo "Règle : connexions établies AUTORISÉES"

# 10. Sauvegarder les règles iptables
sudo apt-get install -y iptables-persistent -q
sudo netfilter-persistent save
echo "Règles iptables sauvegardées"

# 11. Vérification finale
echo ""
echo "=== Règles iptables configurées ==="
sudo iptables -L -v --line-numbers
echo ""
echo "=== Règles NAT ==="
sudo iptables -t nat -L -v
echo ""
echo "=== VM1 Passerelle configurée avec succès ==="
