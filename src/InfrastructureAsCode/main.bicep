@description('Environment of the web app')
param environment string = 'dev'

@description('Location of services')
param location string = resourceGroup().location

var webAppName = '${uniqueString(resourceGroup().id)}-${environment}'
var appServicePlanName = '${uniqueString(resourceGroup().id)}-mpnp-asp'
var logAnalyticsName = '${uniqueString(resourceGroup().id)}-mpnp-la'
var appInsightsName = '${uniqueString(resourceGroup().id)}-mpnp-ai'
var sku = 'P0v3'
var registryName = '${uniqueString(resourceGroup().id)}mpnpreg'
var registrySku = 'Standard'
var imageName = 'techexcel/dotnetcoreapp'
var startupCommand = ''

// TODO: complete this script
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
    name: appServicePlanName
    location: location
    sku: {
        name: sku
    }
    properties: {
        reserved: true
    }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
    name: webAppName
    location: location
    properties: {
        serverFarmId: appServicePlan.id
        siteConfig: {
            appSettings: [
                {
                    name: 'DOCKER_REGISTRY_SERVER_URL'
                    value: 'https://${registryName}.azurecr.io'
                }
                {
                    name: 'DOCKER_REGISTRY_SERVER_USERNAME'
                    value: registry.listCredentials().username
                }
                {
                    name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
                    value: registry.listCredentials().passwords[0].value
                }
                {
                    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
                    value: 'false'
                }
            ]
            linuxFxVersion: 'DOCKER|${registryName}.azurecr.io/${imageName}:latest'
            alwaysOn: true
            appCommandLine: startupCommand
        }
    }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
    name: logAnalyticsName
    location: location
    properties: {
        sku: {
            name: 'PerGB2018'
        }
    }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
    name: appInsightsName
    location: location
    kind: 'web'
    properties: {
        Application_Type: 'web'
        WorkspaceResourceId: logAnalytics.id
    }
}

resource registry 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
    name: registryName
    location: location
    sku: {
        name: registrySku
    }
    properties: {
        adminUserEnabled: true
    }
}

output webAppEndpoint string = webApp.properties.defaultHostName
