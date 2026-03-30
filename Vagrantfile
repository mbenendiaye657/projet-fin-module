Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64" # Ubuntu 22.04 LTS

  # --- VM 1 : PASSERELLE / FIREWALL ---
  config.vm.define "passerelle" do |p|
    p.vm.hostname = "passerelle"
    # Carte 1 : NAT (Internet) — automatique dans Vagrant (eth0)
    # Carte 2 : DMZ
    p.vm.network "private_network", ip: "192.168.100.1", virtualbox__intnet: "dmz-net"
    # Carte 3 : LAN
    p.vm.network "private_network", ip: "192.168.10.1",  virtualbox__intnet: "lan-net"
    p.vm.provider "virtualbox" do |vb|
      vb.name   = "passerelle"
      vb.memory = 512
      vb.cpus   = 1
    end
    p.vm.provision "shell", path: "scripts/setup-passerelle.sh"
  end

  # --- VM 2 : SERVEUR WEB (DMZ) ---
  config.vm.define "web" do |w|
    w.vm.hostname = "serveur-web"
    # Uniquement sur le réseau DMZ
    w.vm.network "private_network", ip: "192.168.100.10", virtualbox__intnet: "dmz-net"
    w.vm.provider "virtualbox" do |vb|
      vb.name   = "serveur-web"
      vb.memory = 1024
      vb.cpus   = 1
    end
    w.vm.provision "shell", path: "scripts/setup-web.sh"
  end

  # --- VM 3 : SERVEUR BASE DE DONNÉES (LAN) ---
  config.vm.define "db" do |d|
    d.vm.hostname = "serveur-db"
    # Uniquement sur le réseau LAN interne
    d.vm.network "private_network", ip: "192.168.10.10", virtualbox__intnet: "lan-net"
    d.vm.provider "virtualbox" do |vb|
      vb.name   = "serveur-db"
      vb.memory = 1024
      vb.cpus   = 1
    end
    d.vm.provision "shell", path: "scripts/setup-db.sh"
  end

end
