Vagrant.configure("2") do |config|
  config.vm.box = "windows-2016-amd64"
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.gui = true
    vb.memory = 2048
    vb.customize ["modifyvm", :id, "--vram", 256]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    vb.customize ["modifyvm", :id, "--accelerate2dvideo", "on"]
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end
  config.vm.network :private_network, ip: '10.10.10.100'
  config.vm.provision "shell", inline: "Uninstall-WindowsFeature Windows-Defender-Features" # because defender slows things down a lot.
  config.vm.provision "reload"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-chocolatey.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-base.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-sql-server.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-sql-server-network-encryption.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-dbeaver.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/powershell/sqlps.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/powershell/sqlclient.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/powershell/create-database-TheSimpsons.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/powershell/use-encrypted-connection.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/python/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/java/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/csharp/run.ps1"
end
