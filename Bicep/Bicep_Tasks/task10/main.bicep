param location string = resourceGroup().location
param resourcePrefix string = 'mkapp'
param sqlAdminlogin string = 'sqladmin'

var logAnalyticsName = '${resourcePrefix}-law'

@secure()
param sqlAdminPassword string

module vnet '../modules/vnet.bicep' = {
  name: 'networkDeployment'
  params: {
    vnetname: '${resourcePrefix}-vnet'
    location: location 
  }
}

module storage '../modules/st.bicep' = {
  name: 'StorageDeploymenrt'
  params: {
    storageName: resourcePrefix
    location: location
    subnetId: vnet.outputs.storagesubnetId
  }
  
}

module sql '../modules/sqlserver.bicep' = {
  name: 'sqlDeployment'
  params: {
    sqlServerName: resourcePrefix
    location: location
    sqlAdminlogin: sqlAdminlogin
    sqlAdminPassword: sqlAdminPassword
    subnetId: vnet.outputs.sqlsubnetId
  }
}

module appService '../modules/appservice.bicep' = {
  name: 'appserviceDeployment'
  params: {
    appname: resourcePrefix
    location: location
    subnetId: vnet.outputs.appsubnetId 
  }
}

module functionApp '../modules/functionapp.bicep' = {
  name: 'FunctionAppDeployment'
  params: {
    location: location
    appname: resourcePrefix
    subnetId: vnet.outputs.functionsubnetId
  }
}

module law '../modules/law.bicep' = {
  name: 'lawDeployment'
  params: {
    logAnalyticsName: logAnalyticsName
    Location: location
  }
}

module trafficManager '../modules/traficmanager.bicep' = {
  name: 'trafficManager'
  params: { 
    location: location
    tmName: resourcePrefix
  }
}

module cdn '../modules/cdn.bicep' = {
  name: 'cdnDeployment'
  params: { 
    location: location
  }
}
