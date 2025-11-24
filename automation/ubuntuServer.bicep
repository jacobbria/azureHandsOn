// Bicep module to deploy general Ubuntu Server 18.04 LTS VM with Public IP and NIC

// PARAMETERS 
param vmName string = 'VM-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param adminUsername string = 'azureuser'
@secure()
param adminPassword string 


// VARIABLES
var vnetName = '${vmName}-vnet'
var subnetName = '${vmName}-subnet'
var publicIPName = '${vmName}-publicip'
var nicName = '${vmName}-nic'
var vmSize = 'Standard_B1s' 
var osDiskType = 'Standard_LRS' 


// RESOURCES 

// 1. Public IP Address 
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static' 
  }
}

// 2. Virtual Network 
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
    name: vnetName
    location: location
    properties:{
        addressSpace: {
            addressPrefixes: [ '10.0.0.0/16']
        }
        subnets: [
            {
                name: subnetName
                properties: {
                    addressPrefix: '10.0.0.0/24'
                }
            }
        ]
    }
}

// 3. Network Interface 
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

// 4. Linux Virtual Machine 
resource LinuxVirtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer' 
        sku: '18.04-LTS' 
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType 
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// OUTPUTS 
output vmPublicIP string = publicIP.properties.ipAddress
