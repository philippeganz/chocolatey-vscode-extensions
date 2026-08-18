# Azure MCP Server Extension for Visual Studio Code


All Azure MCP tools in a single server. The Azure MCP Server implements the [MCP specification](https://modelcontextprotocol.io) to create a seamless connection between AI agents and Azure services. Azure MCP Server can be used alone or with the [GitHub Copilot for Azure extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azure-github-copilot) in VS Code.
## Table of Contents
- [Overview](#overview)
- [Local Setup](#local-setup)
- [Remote Setup](#remote-setup)
- [Usage](#usage)
    - [Getting Started](#getting-started)
    - [Sovereign Cloud Support](#sovereign-cloud-support)
    - [What can you do with the Azure MCP Server?](#what-can-you-do-with-the-azure-mcp-server)
    - [Complete List of Supported Azure Services](#complete-list-of-supported-azure-services)
- [Support and Reference](#support-and-reference)
    - [Documentation](#documentation)
    - [Feedback and Support](#feedback-and-support)
    - [Security](#security)
    - [Permissions and Risk](#permissions-and-risk)
    - [Data Collection](#data-collection)
    - [Compliance Responsibility](#compliance-responsibility)
    - [Third Party Components](#third-party-components)
    - [Export Control](#export-control)
    - [No Warranty / Limitation of Liability](#no-warranty--limitation-of-liability)
    - [Contributing](#contributing)
    - [Code of Conduct](#code-of-conduct)

# Overview

**Azure MCP Server** supercharges your agents with Azure context across **40+ different Azure services**.

# Local Setup
- Install the [Azure MCP Server Visual Studio Code extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azure-mcp-server)
- Start (or Auto-Start) the MCP Server
   > **VS Code (version 1.103 or above):** You can now configure MCP servers to start automatically using the `chat.mcp.autostart` setting, instead of manually restarting them after configuration changes.
   #### **Enable Autostart**
   1. Open **Settings** in VS Code.
   2. Search for `chat.mcp.autostart`.
   3. Select **newAndOutdated** to automatically start MCP servers without manual refresh.
   4. You can also set this from the **refresh icon tooltip** in the Chat view, which also shows which servers will auto-start.
      ![VS Code MCP Autostart Tooltip](https://raw.githubusercontent.com/microsoft/mcp/main/servers/Azure.Mcp.Server/images/vsix/ToolTip.png)
   #### **Manual Start (if autostart is off)**
   1. Open Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`).
   2. Run `MCP: List Servers`.
      ![List Servers](https://raw.githubusercontent.com/microsoft/mcp/main/servers/Azure.Mcp.Server/images/vsix/ListServers.png)
   3. Select `Azure MCP Server ext`, then click **Start Server**.
      ![Select Server](https://raw.githubusercontent.com/microsoft/mcp/main/servers/Azure.Mcp.Server/images/vsix/SelectServer.png)
      ![Start Server](https://raw.githubusercontent.com/microsoft/mcp/main/servers/Azure.Mcp.Server/images/vsix/StartServer.png)
   4. **Check That It's Running**
      - Go to the **Output** tab in VS Code.
      - Look for log messages confirming the server started successfully.
      ![Output](https://raw.githubusercontent.com/microsoft/mcp/main/servers/Azure.Mcp.Server/images/vsix/Output.png)
- (Optional) Configure tools and behavior
    - Full options: control how tools are exposed and whether mutations are allowed:
       ```json
      // Server Mode: collapse per service (default), single tool, or expose every tool
      "azureMcp.serverMode": "namespace", // one of: "single" | "namespace" (default) | "all"
       // Filter which namespaces to expose
       "azureMcp.enabledServices": ["storage", "keyvault"],
       // Run the server in read-only mode (prevents write operations)
       "azureMcp.readOnly": false
       ```
   - Changes take effect after restarting the Azure MCP server from the MCP: List Servers view. (Step 2)
You’re all set! Azure MCP Server is now ready to help you work smarter with Azure resources in VS Code.

# Remote Setup

Host the Azure MCP Server as a remote endpoint when your client requires HTTP-based MCP servers (for example, Microsoft Foundry and Microsoft Copilot Studio) or when you want to share a single deployment across users and environments. The server can be self-hosted on [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/overview).

See the remote hosting [azd templates](https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/azd-templates/README.md) for deployment options.

# Usage

## Getting Started

1. Open GitHub Copilot in [VS Code](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)  and switch to Agent mode.
1. Click `refresh` on the tools list
    - You should see the Azure MCP Server in the list of tools
1. Try a prompt that tells the agent to use the Azure MCP Server, such as `List my Azure Storage containers`
    - The agent should be able to use the Azure MCP Server tools to complete your query
1. Check out the [documentation](https://learn.microsoft.com/azure/developer/azure-mcp-server/) and review the [troubleshooting guide](https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/TROUBLESHOOTING.md) for commonly asked questions
1. We're building this in the open. Your feedback is much appreciated, and will help us shape the future of the Azure MCP server
    - 👉 [Open an issue in the public repository](https://github.com/microsoft/mcp/issues/new/choose)

## Sovereign Cloud Support

Azure MCP Server supports connecting to Azure sovereign clouds. By default, it authenticates against the Azure Public Cloud.

| Cloud | Aliases |
|-------|---------|
| Azure Public Cloud | `AzureCloud`, `AzurePublicCloud`, `Public`, `AzurePublic` |
| Azure China Cloud | `AzureChinaCloud`, `China`, `AzureChina` |
| Azure US Government | `AzureUSGovernment`, `USGov`, `AzureUSGovernmentCloud`, `USGovernment` |

*_The aliases are case insensitive._

Use the `--cloud` option when starting the server, or set the `AZURE_CLOUD` environment variable:

```bash
# Command line
azmcp server start --cloud AzureChinaCloud

# Environment variable (PowerShell)
$env:AZURE_CLOUD = "AzureUSGovernment"
azmcp server start
```

Before connecting, authenticate your local tools against the target cloud:

```bash
# Azure CLI
az cloud set --name AzureChinaCloud
az login

# Azure PowerShell
Connect-AzAccount -Environment AzureChinaCloud
```

For full configuration options, see the [Sovereign Clouds documentation](https://github.com/microsoft/mcp/blob/main/docs/sovereign-clouds.md).

## What can you do with the Azure MCP Server?

✨ The Azure MCP Server supercharges your agents with Azure context. Here are some cool prompts you can try:

### 🧮 Microsoft Foundry

* List Microsoft Foundry models
* Deploy Microsoft Foundry models
* List Microsoft Foundry model deployments
* List knowledge indexes
* Get knowledge index schema configuration
* Create Microsoft Foundry agents
* List Microsoft Foundry agents
* Connect and query Microsoft Foundry agents
* Evaluate Microsoft Foundry agents

### 📊 Azure Advisor

* "List my Advisor recommendations"
* "Apply Advisor recommendations to IaaC files"
* "Before I deploy virtual machines, list the Advisor recommendation metadata that could apply to them"
* "Show Advisor service retirements on or after March 31, 2026"
* "Get Advisor metadata for a recommendation type id"

### 🔎 Azure AI Search

* "What indexes do I have in my Azure AI Search service 'mysvc'?"
* "Let's search this index for 'my search query'"

### 🎤 Azure AI Services Speech

* "Convert this audio file to text using Azure Speech Services"
* "Recognize speech from my audio file with language detection"
* "Transcribe speech from audio with profanity filtering"
* "Transcribe audio with phrase hints for better accuracy"
* "Convert text to speech and save to output.wav"
* "Synthesize speech from 'Hello, welcome to Azure' with Spanish voice"
* "Generate MP3 audio from text with high quality format"

### ⚙️ Azure App Configuration

* "List my App Configuration stores"
* "Show my key-value pairs in App Config"

### ⚙️ Azure App Lens

* "Help me diagnose issues with my app"

### 🕸️ Azure App Service

* "Add a database connection for an App Service web app"
* "List the web apps in my subscription"
* "Show me the web apps in my 'my-resource-group' resource group"
* "Get the details for web app 'my-webapp' in 'my-resource-group'"
* "Get the application settings for my web app 'my-webapp' in 'my-resource-group'"
* "Add application setting 'LogLevel' with value 'INFO' to my 'my-webapp' in 'my-resource-group'"
* "Set application setting 'LogLevel' to 'WARNING' to my 'my-webapp' in 'my-resource-group'"
* "Delete application setting 'LogLevel' from my 'my-webapp' in 'my-resource-group'"
* "List the deployments for web app 'my-webapp' in 'my-resource-group'"
* "Get the deployment 'deployment-id' for web app 'my-webapp' in 'my-resource-group'"
* "List the diagnostic detectors for web app 'my-webapp' in 'my-resource-group'"
* "Diagnose the web app 'my-webapp' with detector 'detector-name' in 'my-resource-group'"
* "Start the web app 'my-webapp' in 'my-resource-group'"
* "Stop the web app 'my-webapp' in 'my-resource-group'"
* "Restart the web app 'my-webapp' in 'my-resource-group'"
* "Soft restart the web app 'my-webapp' in 'my-resource-group' waiting for restart to complete"

### 🛡️ Azure Backup

* "Create a Recovery Services vault named 'myvault' in resource group 'myRG' in eastus with vault-type 'rsv'"
* "Get details of backup vault 'myvault' in resource group 'myRG'"
* "Create a backup policy for Azure VMs in vault 'myvault'"
* "Update backup policy schedule time to 04:00 in vault 'myvault'"
* "List protectable items in my backup vault"
* "Check backup status for my Azure resource in eastus"
* "Get recovery points for a protected item"
* "Find unprotected resources in my subscription"
* "Configure soft delete to 'AlwaysOn' and immutability to 'Locked' on my vault"
* "Enable cross-region restore on my vault"
* "Restore a soft-deleted backup item in vault 'myvault' for datasource '/subscriptions/.../virtualMachines/myvm'"

### 🖥️ Azure CLI Generate

* Generate Azure CLI commands based on user intent

Example prompts that generate Azure CLI commands:

* "Get the details for app service plan 'my-app-service-plan'"

### 🖥️ Azure CLI Install

* Get installation instructions for Azure CLI, Azure Developer CLI and Azure Functions Core Tools CLI for your platform.

### 📞 Azure Communication Services

* "Send an SMS message to +1234567890"
* "Send SMS with delivery reporting enabled"
* "Send a broadcast SMS to multiple recipients"
* "Send SMS with custom tracking tag"
* "Send an email from '[email removed]' to '[email removed]' with subject 'Hello' and message 'Welcome!'"
* "Send an HTML email to multiple recipients with CC and BCC using Azure Communication Services"
* "Send an email with reply-to address '[email removed]' and subject 'Support Request'"
* "Send an email from my communication service endpoint with custom sender name and multiple recipients"
* "Send an email to '[email removed]' and '[email removed]' with subject 'Team Update' and message 'Please review the attached document.'"

### 🖥️ Azure Compute

* "List all my managed disks in subscription 'my-subscription'"
* "Show me all disks in resource group 'my-resource-group'"
* "Get details of disk 'my-disk' in resource group 'my-resource-group'"
* "Create a 128 GB Premium_LRS managed disk named 'my-disk' in resource group 'my-resource-group'"
* "Create a managed disk from snapshot in resource group 'my-resource-group'"
* "Create a disk 'my-disk' in resource group 'my-resource-group' with tags env=prod team=infra"
* "Delete managed disk 'my-disk' in resource group 'my-resource-group'"
* "Update disk 'my-disk' in resource group 'my-resource-group' to 256 GB"
* "Change the SKU of disk 'my-disk' to Premium_LRS"
* "Set the IOPS limit on ultra disk 'my-disk' in resource group 'my-resource-group' to 10000"
* "List all virtual machines in my subscription"
* "Show me all VMs in resource group 'my-resource-group'"
* "Get details for virtual machine 'my-vm' in resource group 'my-resource-group'"
* "Get virtual machine 'my-vm' with instance view including power state and runtime status"
* "Show me the power state and provisioning status of VM 'my-vm'"
* "What is the current status of my virtual machine 'my-vm'?"
* "Create a new VM named 'my-vm' in resource group 'my-rg' for web workloads"
* "Create a Linux VM with Ubuntu 22.04 and SSH key authentication"
* "Create a development VM with Standard_B2s size in East US"
* "Update VM 'my-vm' tags to environment=production"
* "Create a VMSS named 'my-vmss' with 3 instances for web workloads"
* "Update VMSS 'my-vmss' capacity to 5 instances"
* "Delete virtual machine 'my-vm' in resource group 'my-resource-group'"
* "Force delete VM 'my-vm' in resource group 'my-rg' using force-deletion"
* "Start VM 'my-vm' in resource group 'my-rg'"
* "Stop VM 'my-vm' in resource group 'my-rg'"
* "Deallocate VM 'my-vm' in resource group 'my-rg' to stop billing"
* "Restart VM 'my-vm' in resource group 'my-rg'"
* "Delete virtual machine scale set 'my-vmss' in resource group 'my-resource-group'"
* "Force delete VMSS 'my-vmss' in resource group 'my-rg' using force-deletion"

### �📦 Azure Container Apps

* "List the container apps in my subscription"
* "Show me the container apps in my 'my-resource-group' resource group"

### 🔐 Azure Confidential Ledger

* "Append entry {"foo":"bar"} to ledger contoso"
* "Get entry with id 2.40 from ledger contoso"

### 📦 Azure Container Registry (ACR)

* "List all my Azure Container Registries"
* "Show me my container registries in the 'my-resource-group' resource group"
* "List all my Azure Container Registry repositories"

### 📊 Azure Cosmos DB

* "Show me all my Cosmos DB databases"
* "List containers in my Cosmos DB database"
* "Infer the schema of container 'items' in database 'mydb' for Cosmos DB account 'myaccount'"
* "Show me the 15 most recent documents in container 'items' of database 'mydb' in Cosmos DB account 'myaccount'"
* "Get the document with id '123' from container 'items' in database 'mydb' of Cosmos DB account 'myaccount'"
* "Search documents in container 'items' from database 'mydb' where 'description' contains 'wireless headphones'"
* "Find documents similar to 'noise cancelling earbuds' in container 'items' of database 'mydb' using vector property 'embedding'"

### 🧮 Azure Data Explorer

* "Get Azure Data Explorer databases in cluster 'mycluster'"
* "Sample 10 rows from table 'StormEvents' in Azure Data Explorer database 'db1'"

### 📣 Azure Event Grid

* "List all Event Grid topics in subscription 'my-subscription'"
* "Show me the Event Grid topics in my subscription"
* "List all Event Grid topics in resource group 'my-resourcegroup' in my subscription"
* "List Event Grid subscriptions for topic 'my-topic' in resource group 'my-resourcegroup'"
* "List Event Grid subscriptions for topic 'my-topic' in subscription 'my-subscription'"
* "List Event Grid Subscriptions in subscription 'my-subscription'"
* "List Event Grid subscriptions for topic 'my-topic' in location 'my-location'"
* "Publish an event with data '{\"name\": \"test\"}' to topic 'my-topic' using CloudEvents schema"
* "Send custom event data to Event Grid topic 'analytics-events' with EventGrid schema"

### 📂 Azure File Shares

* "Get details about a specific file share in my resource group"
* "Create a new Azure managed file share with NFS protocol"
* "Create a file share with 64 GiB storage, 3000 IOPS, and 125 MiB/s throughput"
* "Update the provisioned storage size of my file share"
* "Update network access settings for my file share"
* "Delete a file share from my resource group"
* "Check if a file share name is available"
* "Get details about a file share snapshot"
* "Create a snapshot of my file share"
* "Update tags on a file share snapshot"
* "Delete a file share snapshot"
* "Get a private endpoint connection for my file share"
* "Update private endpoint connection status to Approved"
* "Delete a private endpoint connection"
* "Get file share limits and quotas for a region"
* "Get provisioning recommendations for my file share workload"
* "Get usage data and metrics for my file share"

### 💡 Azure Insights

* "Generate insights from my current subscription"
* "Summarize what's deployed across my Azure environment and highlight notable patterns"
* "Analyze my tenant and give me insights about the overall infrastructure"
* "What can you tell me about my existing Azure environment?"
* "Analyze subscription <subscription_id> for architectural patterns"
* "Analyze my Azure infrastructure and surface patterns to help me plan my next project"
* "Generate insights about my Azure environment to help me plan a new data analytics platform"
* "What insights can you derive about my subscription to help me plan a containerized microservices workload on AKS?"

### 🌐 Azure IoT Hub

* "Show me IoT Hub 'my-iot-hub' in resource group 'my-resource-group' of my subscription 'my-subscription'"
* "Get details for IoT Hub 'my-iot-hub' in resource group 'my-resource-group' of my subscription 'my-subscription'"

### 🔑 Azure Key Vault

* "List all secrets in my key vault 'my-vault'"
* "Create a new secret called 'apiKey' with value 'xyz' in key vault 'my-vault'"
* "List all keys in key vault 'my-vault'"
* "Create a new RSA key called 'encryption-key' in key vault 'my-vault'"
* "List all certificates in key vault 'my-vault'"
* "Import a certificate file into key vault 'my-vault' using the name 'tls-cert'"
* "Get the account settings for my key vault 'my-vault'"

### ☸️ Azure Kubernetes Service (AKS)

* "List my AKS clusters in my subscription"
* "Show me all my Azure Kubernetes Service clusters"
* "List the node pools for my AKS cluster"
* "Get details for the node pool 'np1' of my AKS cluster 'my-aks-cluster' in the 'my-resource-group' resource group"

### ⚡ Azure Managed Lustre

* "List the Azure Managed Lustre clusters in resource group 'my-resource-group'"
* "How many IP Addresses I need to create a 128 TiB cluster of AMLFS 500?"
* "Check if 'my-subnet-id' can host an Azure Managed Lustre with 'my-size' TiB and 'my-sku' in 'my-region'
* Create a 4 TIB Azure Managed Lustre filesystem in 'my-region' attaching to 'my-subnet' in virtual network 'my-virtual-network'

### 📊 Azure Monitor

* "Query my Log Analytics workspace"
* "List my Azure Monitor Health Models"
* "Get details for my Azure Monitor Health Model 'my-health-model'"

### 🧭 Azure Monitor Instrumentation (under Azure Monitor)

* "List available Azure Monitor onboarding learning resources"
* "Get the learning resource at 'concepts/dotnet/opentelemetry-pipeline.md'"
* "Start Azure Monitor instrumentation orchestration for my local workspace"
* "Continue to the next orchestration step after I complete the previous action"
* "Send brownfield analysis findings to continue migration planning"

### 🔧 Azure Resource Management

* "List my resource groups"
* "List my Azure CDN endpoints"
* "Help me build an Azure application using Node.js"

### 🗄️ Azure SQL Database

* "List all SQL servers in my subscription"
* "List all SQL servers in my resource group 'my-resource-group'"
* "Show me details about my Azure SQL database 'mydb'"
* "List all databases in my Azure SQL server 'myserver'"
* "Update the performance tier of my Azure SQL database 'mydb'"
* "Rename my Azure SQL database 'mydb' to 'newname'"
* "List all firewall rules for my Azure SQL server 'myserver'"
* "Create a firewall rule for my Azure SQL server 'myserver'"
* "Delete a firewall rule from my Azure SQL server 'myserver'"
* "List all elastic pools in my Azure SQL server 'myserver'"
* "List Active Directory administrators for my Azure SQL server 'myserver'"
* "Create a new Azure SQL server in my resource group 'my-resource-group'"
* "Show me details about my Azure SQL server 'myserver'"
* "Delete my Azure SQL server 'myserver'"

### 🤖 Azure SRE Agent

* "List my Azure SRE Agent resources"
* "Show me the SRE sub-agent named 'incident-bot' on agent 'sre-prod'"
* "Create a new SRE sub-agent named 'incident-bot' with these instructions on agent 'sre-prod'"
* "List the connectors registered on SRE Agent 'sre-prod'"
* "Register a Kusto connector on SRE Agent 'sre-prod' pointing at cluster 'https://help.kusto.windows.net'"
* "Register an MCP connector on SRE Agent 'sre-prod' for the Azure MCP server"
* "List the safety hooks configured on SRE Agent 'sre-prod'"
* "Activate the 'pre-prod-approval' hook for thread 'thread-123' on SRE Agent 'sre-prod'"
* "Create a new investigation thread on SRE Agent 'sre-prod' and ask it to look into elevated 5xx in payments-api"
* "Send a follow-up message to thread 'thread-123' on SRE Agent 'sre-prod'"
* "Run an autonomous investigation on SRE Agent 'sre-prod' with up to 20 iterations"
* "List scheduled tasks on SRE Agent 'sre-prod'"
* "Create a scheduled task on SRE Agent 'sre-prod' that runs every 15 minutes"
* "List active incidents on SRE Agent 'sre-prod'"
* "Declare an incident on SRE Agent 'sre-prod' for elevated error rates"
* "Generate a remediation workflow on SRE Agent 'sre-prod' from the latest investigation"
* "Search SRE Agent 'sre-prod' memories for prior occurrences of this alert"
* "Produce a remediation plan on SRE Agent 'sre-prod' for incident 'inc-42'"

### 💾 Azure Storage

* "List my Azure storage accounts"
* "Get details about my storage account 'mystorageaccount'"
* "Create a new storage account in East US with Data Lake support"
* "Get details about my Storage container"
* "Upload my file to the blob container"

### 🔄 Azure Migrate

* "Generate a Platform Landing Zone"
* "Turn off DDoS protection in my Platform Landing Zone"
* "Turn off Bastion host in my Platform Landing Zone"

### 🛡️ Azure Resilience Management

* "List all resilience goal templates in service group 'my-service-group'"
* "Get the details of goal template 'my-template' in service group 'my-service-group'"
* "List all resilience goal assignments in service group 'my-service-group'"
* "List the resources of goal assignment 'my-assignment' in service group 'my-service-group'"
* "List my resilience usage plans in resource group 'my-rg'"
* "List the enrollments of usage plan 'my-plan' in resource group 'my-rg'"
* "List all resilience recovery plans in service group 'my-service-group'"
* "Get the recovery plan 'my-recovery-plan' in service group 'my-service-group'"
* "List the recovery jobs of recovery plan 'my-recovery-plan' in service group 'my-service-group'"
* "Create a Basic resilience usage plan 'my-plan' in resource group 'my-rg'"
* "Enroll service group 'my-service-group' into usage plan 'my-plan' in resource group 'my-rg'"

### Azure Resource Manager

* Use Azure resource graph to query Azure resources
* Create, view and cancel ARM template deployments

### Azure Terraform

* "Get the documentation for azurerm_virtual_network"
* "Show me the arguments for azurerm_storage_account"
* "Get AzAPI documentation for Microsoft.Storage/storageAccounts"
* "Get AzAPI docs for Microsoft.Compute/virtualMachines with API version 2024-07-01"
* "List all available Azure Verified Modules"
* "Show all versions of avm-res-network-virtualnetwork"
* "Get the documentation for avm-res-storage-storageaccount version 0.1.0"
* "Get the documentation for the avm-ptn-aiml-ai-foundry pattern module"
* "Export all resources in resource group my-rg to Terraform"
* "Export all storage accounts in my subscription using a resource graph query"
* "Validate Terraform files in ./my-terraform-folder against Azure security policies"
* "Validate my Terraform plan file against Azure-Proactive-Resiliency-Library-v2 policies"

### 🏛️ Azure Well-Architected Framework

* "List all services with Well-Architected Framework guidance"
* "What services have architectural guidance?"
* "Get Well-Architected Framework guidance for App Service"
* "What's the architectural guidance for Azure Cosmos DB?"

## Complete List of Supported Azure Services

The Azure MCP Server provides tools for interacting with **44+ Azure service areas**:

- 🧮 **Microsoft Foundry** - AI model management, AI model deployment, and knowledge index management
- 📊 **Azure Advisor** - Advisor recommendations
- 🔎 **Azure AI Search** - Search engine/vector database operations
- 🎤 **Azure AI Services Speech** - Speech-to-text recognition and text-to-speech synthesis
- ⚙️ **Azure App Configuration** - Configuration management
- 🕸️ **Azure App Service** - Web app hosting
- 🛡️ **Azure Backup** - Recovery Services vault management, backup policies, protection, jobs, recovery points, governance, and disaster recovery
- 🛡️ **Azure Best Practices** - Secure, production-grade guidance
- 🖥️ **Azure CLI Generate** - Generate Azure CLI commands from natural language
- 📞 **Azure Communication Services** - SMS messaging and communication
- � **Azure Compute** - Virtual Machine, Virtual Machine Scale Set, and Disk management
- �🔐 **Azure Confidential Ledger** - Tamper-proof ledger operations
- 📦 **Azure Container Apps** - Container hosting
- 📦 **Azure Container Registry (ACR)** - Container registry management
- 📊 **Azure Cosmos DB** - NoSQL database operations
- 🧮 **Azure Data Explorer** - Analytics queries and KQL
- 🐬 **Azure Database for MySQL** - MySQL database management
- 🐘 **Azure Database for PostgreSQL** - PostgreSQL database management
- 🏭 **Azure Device Registry** - Device Registry namespace management
- 📊 **Azure Event Grid** - Event routing and management
- 📁 **Azure File Shares** - Azure managed file share operations
- ⚡ **Azure Functions** - Function App management and functions project files, language support, and templates source code
- 💡 **Azure Insights** - Derive infrastructure insights from Azure Resource Graph patterns
- 🌐 **Azure IoT Hub** - IoT Hub resource discovery and details
- 🔑 **Azure Key Vault** - Secrets, keys, and certificates
- ☸️ **Azure Kubernetes Service (AKS)** - Container orchestration
- 📦 **Azure Load Testing** - Performance testing
- 🚀 **Azure Managed Grafana** - Monitoring dashboards
- 🗃️ **Azure Managed Lustre** - High-performance Lustre filesystem operations
- 🏪 **Azure Marketplace** - Product discovery
- 🔄 **Azure Migrate** - Platform Landing Zone generation and modification guidance
- 📈 **Azure Monitor** - Logging, metrics, health models, health monitoring, and instrumentation onboarding/migration workflow for local applications
- ⚖️ **Azure Policy** - Policies set to enforce organizational standards
- ⚙️ **Azure Native ISV Services** - Third-party integrations
- 🛡️ **Azure Quick Review CLI** - Compliance scanning
- 📊 **Azure Quota** - Resource quota and usage management
- 🎭 **Azure RBAC** - Access control management
- 🔴 **Azure Redis Cache** - In-memory data store
- 🛡️ **Azure Resilience Management** - Resilience goal templates, goal assignments, goal resources, usage plans, usage plan enrollments, recovery plans, recovery plan resources, recovery jobs, and recovery job resources
- 🏗️ **Azure Resource Groups** - Resource organization
- 🚌 **Azure Service Bus** - Message queuing
- 🧵 **Azure Service Fabric** - Managed cluster node operations
- 🏥 **Azure Service Health** - Resource health status and availability
- 🗄️ **Azure SQL Database** - Relational database management
- 🗄️ **Azure SQL Elastic Pool** - Database resource sharing
- 🗄️ **Azure SQL Server** - Server administration
- 🤖 **Azure SRE Agent** - SRE Agent investigations, sub-agents, connectors, hooks, threads, scheduled tasks, incidents, workflows, memories, and remediation plans
- 💾 **Azure Storage** - Blob storage
-  **Azure Storage Sync** - Azure File Sync management operations
- 📋 **Azure Subscription** - Subscription management
- 🏗️ **Azure Terraform** - Terraform provider documentation, Azure Verified Modules, resource export, and policy validation
- 🏗️ **Azure Terraform Best Practices** - Infrastructure as code guidance
- 🖥️ **Azure Virtual Desktop** - Virtual desktop infrastructure
- 🏛️ **Azure Well-Architected Framework** - Architectural best practices and design patterns
- 📊 **Azure Workbooks** - Custom visualizations
- 🏗️ **Bicep** - Azure resource templates
- 🏗️ **Cloud Architect** - Guided architecture design

# Support and Reference

## Documentation

- See our [official documentation on learn.microsoft.com](https://learn.microsoft.com/azure/developer/azure-mcp-server/) to learn how to use the Azure MCP Server to interact with Azure resources through natural language commands from AI agents and other types of clients.
- For additional command documentation and examples, see [Azure MCP Commands](https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/docs/azmcp-commands.md).
- Use [Prompt Templates](https://github.com/microsoft/mcp/blob/main/docs/prompt-templates.md) to set tenant and subscription context once at the beginning of your Copilot session, avoiding repetitive information in subsequent prompts.

## Feedback and Support

- Check the [Troubleshooting guide](https://aka.ms/azmcp/troubleshooting) to diagnose and resolve common issues with the Azure MCP Server.
- Review the [Known Issues](https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/KNOWN-ISSUES.md) for current limitations and workarounds.
- For advanced troubleshooting, you can enable [support logging](https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/TROUBLESHOOTING.md#support-logging) using the `--dangerously-write-support-logs-to-dir` option.
- We're building this in the open. Your feedback is much appreciated, and will help us shape the future of the Azure MCP server.
    - 👉 [Open an issue](https://github.com/microsoft/mcp/issues) in the public GitHub repository — we’d love to hear from you!

## Security

Your credentials are always handled securely through the official [Azure Identity SDK](https://github.com/Azure/azure-sdk-for-net/blob/main/sdk/identity/Azure.Identity/README.md) - **we never store or manage tokens directly**.

MCP as a phenomenon is very novel and cutting-edge. As with all new technology standards, consider doing a security review to ensure any systems that integrate with MCP servers follow all regulations and standards your system is expected to adhere to. This includes not only the Azure MCP Server, but any MCP client/agent that you choose to implement down to the model provider.

You should follow Microsoft security guidance for MCP servers, including enabling Entra ID authentication, secure token management, and network isolation. Refer to [Microsoft Security Documentation](https://learn.microsoft.com/azure/api-management/secure-mcp-servers) for details.

## Permissions and Risk

MCP clients can invoke operations based on the user’s Azure RBAC permissions. Autonomous or misconfigured clients may perform destructive actions. You should review and apply least-privilege RBAC roles and implement safeguards before deployment. Certain safeguards, such as flags to prevent destructive operations, are not standardized in the MCP specification and may not be supported by all clients.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry by following the instructions [here](https://code.visualstudio.com/docs/configure/telemetry#_disable-telemetry-reporting).


## Compliance Responsibility

This MCP server may interact with clients and services outside Microsoft compliance boundaries. You are responsible for ensuring that any integration complies with applicable organizational, regulatory, and contractual requirements.

## Third Party Components

This MCP server may use or depend on third party components. You are responsible for reviewing and complying with the licenses and security posture of any third-party components.

## Export Control

Use of this software must comply with all applicable export laws and regulations, including U.S. Export Administration Regulations and local jurisdiction requirements.

## No Warranty / Limitation of Liability

This software is provided “as is” without warranties or conditions of any kind, either express or implied. Microsoft shall not be liable for any damages arising from use, misuse, or misconfiguration of this software.

## Contributing

We welcome contributions to the Azure MCP Server! Whether you're fixing bugs, adding new features, or improving documentation, your contributions are welcome.

Please read our [Contributing Guide](https://github.com/microsoft/mcp/blob/main/CONTRIBUTING.md) for guidelines on:

* 🛠️ Setting up your development environment
* ✨ Adding new commands
* 📝 Code style and testing requirements
* 🔄 Making pull requests


## Code of Conduct

This project has adopted the
[Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information, see the
[Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [[email removed]](mailto:[email removed])
with any additional questions or comments.
