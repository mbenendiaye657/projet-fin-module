# projet-fin-module — OpenShift Virtualization + GitHub CI/CD

> Repo GitHub : **mbenendiaye657/projet-fin-module**  
> Namespace OpenShift : **mbened-dev**

## Architecture

```
Internet (NAT)
      │
      ▼
┌─────────────────────────────────┐
│  VM1 — Passerelle / Firewall    │  Ubuntu 22.04 + iptables
│  eth0 : NAT (Internet)          │
└────────────┬────────────────────┘
             │
     ┌───────┴──────────────────────┐
     │                              │
     ▼                              ▼
┌─────────────────┐      ┌──────────────────────┐
│  Zone DMZ       │      │  Réseau LAN           │
│  192.168.100.0  │      │  192.168.10.0/24      │
│  VM2 — Web      │ ───► │  VM3 — MySQL 8.0      │
│  Nginx          │      │  (container)          │
└─────────────────┘      └──────────────────────┘
```

## Structure

```
projet-fin-module/
├── .github/workflows/deploy.yml
├── manifests/
│   ├── network/
│   │   ├── 00-namespace.yaml
│   │   ├── 01-nad-dmz.yaml
│   │   ├── 02-nad-lan.yaml
│   │   ├── 03-networkpolicy-deny-all.yaml
│   │   └── 04-networkpolicy-allow-web-db.yaml
│   ├── vms/
│   │   ├── 05-secret-mysql.yaml
│   │   ├── 06-vm-firewall.yaml
│   │   ├── 07-vm-web.yaml
│   │   └── 08-vm-db.yaml
│   └── services/
│       ├── 09-svc-web.yaml
│       ├── 10-svc-db.yaml
│       └── 11-route-web.yaml
└── README.md
```

## Déploiement manuel

```bash
# 1. Réseau
oc apply -f manifests/network/03-networkpolicy-deny-all.yaml
oc apply -f manifests/network/04-networkpolicy-allow-web-db.yaml

# 2. Secret MySQL
oc apply -f manifests/vms/05-secret-mysql.yaml

# 3. VMs et DB
oc apply -f manifests/vms/ -n mbened-dev

# 4. Démarrer les VMs
virtctl start vm-firewall -n mbened-dev
virtctl start vm-web -n mbened-dev

# 5. Services et Route
oc apply -f manifests/services/ -n mbened-dev

# 6. Récupérer l'URL publique
oc get route web-route -n mbened-dev -o jsonpath='{.spec.host}'
```

## Sécurité réseau

- **Deny all** : tout le trafic bloqué par défaut
- **Allow web → db** : seul VM2 peut joindre MySQL sur le port 3306
- **Internet → VM3** : impossible (NetworkPolicy)
- **Firewall** : NAT et filtrage iptables

## Auteur

**mbenendiaye657** — [github.com/mbenendiaye657/projet-fin-module](https://github.com/mbenendiaye657/projet-fin-module)
