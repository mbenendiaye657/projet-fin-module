# projet-fin-module — Architecture 3-Tiers Virtualisée

> **Étudiant** : mbenendiaye657  
> **Hyperviseur** : VirtualBox (Type 2) + Vagrant  
> **OS invités** : Ubuntu 22.04 LTS

---

## Architecture

```
Internet (NAT)
      │
      ▼
┌─────────────────────────────────────────────┐
│  VM1 — Passerelle / Firewall                │
│  eth0 : NAT Internet (auto Vagrant)         │
│  eth1 : 192.168.100.1  (DMZ)               │
│  eth2 : 192.168.10.1   (LAN)               │
│  OS   : Ubuntu 22.04 + iptables             │
└──────────────┬──────────────────────────────┘
               │
       ┌───────┴────────────────────┐
       │                            │
       ▼                            ▼
┌──────────────────┐    ┌───────────────────────┐
│  Zone DMZ        │    │  Réseau LAN            │
│  192.168.100.0/24│    │  192.168.10.0/24       │
│                  │    │                        │
│  VM2 — Web       │    │  VM3 — Base de données │
│  192.168.100.10  │    │  192.168.10.10         │
│  Nginx + Node.js │    │  MySQL 8.0             │
└──────────────────┘    └───────────────────────┘
```

---

## Règles réseau

| Source       | Destination     | Port      | Résultat     |
|--------------|-----------------|-----------|--------------|
| Internet     | VM2 Web         | 80 / 443  | ✅ Autorisé  |
| Internet     | VM3 DB          | 3306      | ❌ Bloqué    |
| VM2 Web      | Internet        | *         | ✅ Autorisé  |
| VM2 Web      | VM3 DB          | *         | ❌ Bloqué    |
| VM3 DB       | VM2 Web         | *         | ✅ Autorisé  |
| VM3 DB       | Internet        | *         | ✅ Autorisé  |

---

## Prérequis

- [VirtualBox](https://www.virtualbox.org/) installé
- [Vagrant](https://www.vagrantup.com/) installé
- 8 Go RAM minimum recommandés

---

## Structure du projet

```
projet-3-tiers-openshift/
├── Vagrantfile              ← Définition des 3 VMs
├── README.md
├── app/
│   ├── server.js            ← Application Node.js (VM2)
│   └── package.json
└── scripts/
    ├── setup-passerelle.sh  ← Configuration iptables VM1
    ├── setup-web.sh         ← Installation Nginx + Node.js VM2
    └── setup-db.sh          ← Installation MySQL VM3
```

---

## Démarrage

```bash
# Cloner le projet
git clone https://github.com/mbenendiaye657/projet-fin-module.git
cd projet-fin-module

# Démarrer toutes les VMs (peut prendre 10-15 minutes)
vagrant up

# Vérifier l'état
vagrant status
```

---

## Connexion aux VMs

```bash
vagrant ssh passerelle   # VM1 — Firewall
vagrant ssh web          # VM2 — Serveur Web
vagrant ssh db           # VM3 — Base de données
```

---

## Tests de validation

### Depuis la passerelle (VM1)
```bash
vagrant ssh passerelle

# Voir les règles iptables
sudo iptables -L -v --line-numbers

# Ping Internet
ping -c 3 8.8.8.8

# Ping VM2
ping -c 3 192.168.100.10

# Ping VM3
ping -c 3 192.168.10.10
```

### Depuis VM2 (Web)
```bash
vagrant ssh web

# Ping Internet (doit fonctionner)
ping -c 3 8.8.8.8

# Test app Node.js
curl http://localhost

# Test connexion MySQL vers VM3
mysql -h 192.168.10.10 -u appuser -p'apppassword123' appdb -e "SELECT * FROM messages;"

# VM2 -> VM3 direct via passerelle (doit être BLOQUÉ)
# ping -c 3 192.168.10.10  <- bloqué par iptables
```

### Depuis VM3 (DB)
```bash
vagrant ssh db

# Ping Internet (doit fonctionner)
ping -c 3 8.8.8.8

# Ping VM2 (doit fonctionner)
ping -c 3 192.168.100.10

# Vérifier MySQL
sudo systemctl status mysql
mysql -e "SELECT * FROM appdb.messages;"
```

### Accès Web depuis l'hôte
```
http://192.168.100.10
```

---

## Commandes Vagrant utiles

```bash
vagrant up              # Démarrer toutes les VMs
vagrant halt            # Arrêter toutes les VMs
vagrant destroy         # Supprimer toutes les VMs
vagrant reload          # Redémarrer les VMs
vagrant provision       # Rejouer les scripts de provisioning
vagrant status          # État des VMs
```

---

## Auteur

**mbenendiaye657** — Projet Fin de Module | Administration Cloud & Virtualisation
