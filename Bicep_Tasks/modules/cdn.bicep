param location string

resource cdn 'Microsoft.Cdn/profiles@2024-09-01' = {
  name: 'mycdn'
  location: location
  sku: {
    name: 'Standard_Microsoft'
  }
}
