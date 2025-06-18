ip_address = '10.10.10.100'

Vagrant.configure("2") do |config|
  config.vm.box = "windows-2022-amd64"

  config.vm.provider "libvirt" do |lv, config|
    lv.memory = 4*1024
    lv.cpus = 2
    lv.cpu_mode = "host-passthrough"
    #lv.nested = true
    lv.keymap = "pt"
    config.vm.synced_folder ".", "/vagrant", type: "smb", smb_username: ENV["USER"], smb_password: ENV["VAGRANT_SMB_PASSWORD"]
  end
  
  config.vm.hostname = 'mssql'
  config.vm.network :private_network, ip: ip_address
  config.vm.provision "shell", path: "ps.ps1", args: "provision-chocolatey.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-base.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-sql-server.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: ["provision-sql-server-network-encryption.ps1", ip_address]
  config.vm.provision "shell", path: "ps.ps1", args: "provision-sql-server-management-studio.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/powershell/sqlps.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/powershell/sqlclient.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/powershell/create-database-TheSimpsons.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/powershell/use-encrypted-connection.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/python/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/java/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/csharp/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/go/run.ps1"
end
