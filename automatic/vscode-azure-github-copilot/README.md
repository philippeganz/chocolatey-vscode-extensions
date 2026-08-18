# What's GitHub Copilot for Azure?

GitHub Copilot for Azure is a Visual Studio Code extension that includes a set of Azure skills for specialized domain knowledge, and integrates support for GitHub Copilot agent and ask modes. Use Azure skills for deep, service-specific guidance, leverage Azure tools in agent mode to automatically complete Azure tasks, or chat with @azure in ask mode to get help with Azure services, development for Azure, and Azure DevOps tasks. Go to the [release notes](https://aka.ms/azcode/copilot/changelog) for details on the latest updates.

**Azure Skills**
![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/azureSkillsIntroEdited.gif)

**Agent mode**
![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/agentModeIntro.gif)

**Ask mode**
![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/intro.gif)

> **Note:** GitHub Copilot for Azure currently only supports Windows x64, Windows ARM64, macOS x64, macOS ARM64 and Linux x64.

## Azure Skills

GitHub Copilot for Azure includes a set of Azure skills that provide specialized domain knowledge and workflows for Azure services. Skills can be easily installed using the built-in commands and work with agent mode.

Core skills for deploying applications to Azure include:

- **azure-prepare** – Prepares your application for Azure deployment by generating infrastructure-as-code (Bicep or Terraform), azure.yaml, and Dockerfiles. Use this skill to create, modernize, or set up applications for Azure hosting.
- **azure-validate** – Validates your deployment configuration and infrastructure files to catch issues before deploying, ensuring your application is ready for Azure.
- **azure-deploy** – Executes Azure deployments for prepared applications using `azd up`, `azd deploy`, `terraform apply`, or `az deployment` commands with built-in error recovery.

View the full list of available skills at [github.com/microsoft/azure-skills](https://github.com/microsoft/azure-skills).

### Installation

Github Copilot for Azure installs skills at activation. At that point, you may see a toast like the following:

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/skillsToastPic.png)

If you don't see the toast notification, you can manually install them either globally or locally using the commands listed below. To remove local skills, delete the corresponding files from `.agents/skills/`. Uninstalling the extension will uninstall the Azure Skills globally.

- **`@azure: Install Azure Skills Globally`** – Installs Azure skills into the global (home directory) location, making them available across all workspaces.
- **`@azure: Uninstall Azure Skills Globally`** – Removes all globally installed Azure skills.
- **`@azure: Install Azure Skills Locally`** – Installs Azure skills into the current workspace directory (under `.agents/skills/`).

## Agent mode

Agent mode can help you complete Azure-related tasks by automatically using tools from GitHub Copilot for Azure. You can let agent mode decide on those tools, or you can guide the process by choosing particular tools from the GitHub Copilot for Azure toolset.
GitHub Copilot for Azure tools include:

### General

- **`#azure_dotnet_template_tags`:** Gets the list of tags that can be used to filter the available dotnet templates.
- **`#azure_get_dotnet_templates_for_tag`:** Gets the list of dotnet project templates available for `dotnet new` commands that match the given tag.

### Resource Information

- **`#azure_query_azure_resource_graph`:** Queries the Azure Resource Graph for information about resources, subscriptions, and resource groups that you have access to. It is used to obtain detailed information about your resources.

### Account Information

- **`#azure_get_auth_context`:** Gets the current authentication state, including which account you are signed in to, the current tenant in use, and the default subscriptions selected.
- **`#azure_set_auth_context`:** Sets the current authentication state. You can switch to a different account, change the tenant in use, or select default subscriptions.

### Azure MCP

GitHub Copilot for Azure installs the Azure MCP Server extension as a dependency. Azure MCP Server offers a wide range of tools for developing applications using Azure services. You can learn more about the tools Azure MCP Server offers in this [documentation](https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/docs/azmcp-commands.md).

### Custom Agents

GitHub Copilot for Azure includes several custom agents that provide specialized workflows for specific Azure tasks:

#### Infrastructure as Code (IaC) Agents

- **Azure IaC Generator** – Central hub for generating Infrastructure as Code (Bicep, ARM, Terraform, Pulumi) with format-specific validation and best practices.
- **Azure IaC Exporter** – Export existing Azure resources to Infrastructure as Code templates via Azure Resource Graph analysis and Azure Resource Manager API calls.

#### Deployment & Migration Agents

- **DeployToAzure** – Custom agent focusing on deploying Azure resources.
- **LambdaToFunctionMigration** – Migrate AWS Lambda functions to Azure Functions with comprehensive support for assessment, code migration, infrastructure generation, validation, and deployment.
- **Azure_function_codegen_and_deployment** – Generate and deploy Azure Functions with comprehensive planning, code generation, and deployment automation.
- **Azure_Static_Web_App** – Create and deploy Azure Static Web Apps.

#### Cost Optimization Agents

- **AzureCostOptimizeAgent** – Identify, quantify, and recommend cost savings across an Azure subscription.
- **AzqrCostOptimizeAgent** – Use Azure Quick Review (azqr) to identify cost-impacting issues and quick wins.

#### Specialized Builders

- **MCP AppService Builder** – Plan, scaffold, extend, and deploy .NET 10 MCP App Service MCP servers with azd/Bicep and RBAC.

### Custom Prompts

GitHub Copilot for Azure includes custom prompts for AWS Lambda to Azure Functions migration workflow:

- **LambdaMigration-Phase1-AssessLambdaProject** – Assess the AWS Lambda codebase for migration to Azure Functions.
- **LambdaMigration-Phase2-MigrateLambdaCode** – Migrate AWS Lambda code to Azure Functions.
- **LambdaMigration-Phase3-GenerateFunctionsInfra** – Generate infrastructure as code files for the Azure Functions project.
- **LambdaMigration-Phase4-ValidateCode** – Validate the migrated Azure Functions code.
- **LambdaMigration-Phase5-ValidateInfra** – Validate the infrastructure as code files.
- **LambdaMigration-Phase6-DeployToAzure** – Deploy resources to Azure.
- **LambdaMigration-GetStatus** – Retrieve the current status of the migration.


## How do I use GitHub Copilot for Azure tools in agent mode?

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/setModeToAgent.png)

1. Set mode to **Agent** in Chat.
1. Select your model. We recommend using Claude models such as Claude Opus for improved tool invocation.
1. Try to include details in your prompts, especially about your Azure resources.

Alternatively, if you want to select a specific tool, you can say `#<name of the tool>`, followed by your prompt.
For general guidance on using agent mode, visit [Use Agent mode in VS Code](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode).

Examples of prompts:

- Create an Azure storage account and connect to a file upload app
- Deploy a local Python Flask app to Azure
- Create a ToDo web app and deploy it to Azure
- Create a bicep file to deploy a MySQL database to West US 3 region

## Ask mode

Ask mode can help you use natural language to interact with large language models to ask questions about the following Azure topics:

- **Learn about Azure:** @azure can help with your questions about a variety of Azure services and technologies, such as AI, compute, containers, databases, DevOps, network, security, and storage.

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/learn.gif)

- **Resource management:** @azure can help with getting information about your Azure resources, including summarizing resource usage and resource-specific questions.

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/resources.gif)

- **Diagnostics:** @azure can help diagnose problems with services, such as Azure API Management, Azure Cache for Redis, Azure Container Apps, Azure Functions, Azure Kubernetes Services, and the Web Apps feature of Azure App Service.

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/diagnose.gif)

- **Cost management:** @azure can help estimate historical Azure costs.

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/cost.gif)

- **Azure Developer CLI (azd) support:** @azure can help you search for application templates and will provide instructions for how to initialize, configure, and deploy.

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/deploy_init.gif)

- **Bicep template generation:** @azure can help create a Bicep template for building Azure infrastructure.

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/bicep.gif)

- **Terraform template generation:** @azure can help create a Terraform template for building Azure infrastructure.

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/terraform.gif)

## How do I chat with @azure in ask mode?

![image](https://github.com/microsoft/GitHub-Copilot-for-Azure/raw/HEAD/resources/readme/setModeToAsk.png)

1. Set mode to **Ask** in Chat.
1. Enter **@azure** to begin the conversation.
1. Try to include details in your prompts, especially about your Azure resources, such as the specific resource and subscription ID. Ask follow-up questions if you need more information.

You can also find a shortcut in the context menu for items in the Azure Resources view.

Examples of prompts:

**Learn about Azure**

- @azure What kinds of AI services does Azure offer?
- @azure What’s the difference between Azure Container Apps and Azure Kubernetes Service?

**Resource management**

- @azure What’s the URL for my webapp named [insert name]?
- @azure How many storage accounts do I have in eastus?

**Diagnostics and troubleshooting**

- @azure Summarize the recent logs in my Azure Container Apps/Azure Kubernetes Service application
- @azure Help me diagnose a problem with Azure Kubernetes Service

**Cost management**

- @azure Can you show me the cost breakdown by service for Aug 2024 for my current subscription?
- @azure What was my most expensive resource last month?

**Azure Developer CLI (azd) support**

- @azure Help me deploy my azd template to the cloud
- @azure I'd like to build a Python web API with a MongoDB database and a React.js front end

**Bicep template generation**

- @azure Give me a Bicep template for creating a key vault, a managed identity, and a role assignment for the managed identity to access the key vault
- @azure Show me a Bicep template that creates an Azure Storage account with a blob container and a file share

**Terraform template generation**

- @azure Show me a Terraform configuration that creates a web app named "mywebapp"
- @azure Give me a terraform template to create a VM with a public IP address

## How do I get started?

To use GitHub Copilot for Azure, you’ll need:

- An active GitHub Copilot license.
- The GitHub Copilot Chat extension.
- A Microsoft account.

New to Azure? Sign up for free and get a $200 credit to use on Azure services. [Learn more about Azure](https://www.azure.com)

## Commands

- **`@azure: Install Azure Skills Globally`** – Installs Azure skills into the global (home directory) location, making them available across all workspaces.
- **`@azure: Uninstall Azure Skills Globally`** – Removes all globally installed Azure skills.
- **`@azure: Install Azure Skills Locally`** – Installs Azure skills into the current workspace directory (under `.agents/skills/`).
- **`@azure: Show output channel`** – Opens the Azure output channel for viewing skill-related logs and diagnostics.
- **`@azure: Make a feature request`** - Opens the GitHub feature request issue template in your default browser at the GitHub Copilot for Azure repository.
- **`@azure: Report an issue`** - Opens the GitHub bug report issue template in your default browser, pre-filled with your app version and platform details (OS, architecture, release).

## Privacy and preview terms

By using GitHub Copilot Chat, you agree to [GitHub Copilot Chat preview terms](https://docs.github.com/en/copilot/responsible-use-of-github-copilot-features/responsible-use-of-github-copilot-chat-in-your-ide). Review the [transparency note](https://aka.ms/GitHubCopilotForAzureTransparency) to learn about usage, limitations, and ways to improve Copilot Chat during the technical preview.

Your code is yours. We follow responsible practices in accordance with our [Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement) to ensure that your code snippets will not be used as suggested code for other users of GitHub Copilot.

To get up-to-date security fixes, use the latest version of the Copilot extension and Visual Studio Code.

## Telemetry

Visual Studio Code collects usage data and sends it to Microsoft to help improve our products and services. Read the [Microsoft Privacy Statement](https://www.microsoft.com/privacy/privacystatement) to learn more. If you don't want to send usage data to Microsoft, you can set the `telemetry.enableTelemetry` setting to `false`. Get more information in the [FAQ section](https://code.visualstudio.com/docs/supporting/faq#_how-to-disable-telemetry-reporting).

## More information about GitHub Copilot for Azure and GitHub Copilot

[Learn more](https://aka.ms/LearnAboutGitHubCopilotForAzure) about GitHub Copilot for Azure.

[Sign up](https://github.com/settings/copilot?utm_source=vscode-chat-readme&utm_medium=third&utm_campaign=2024q3-em-MSFT-signup) for a free trial of GitHub Copilot.

- If you're using Copilot for your business, learn more about [Copilot Business](https://docs.github.com/en/copilot/copilot-business/about-github-copilot-business) and [Copilot Enterprise](https://docs.github.com/en/copilot/github-copilot-enterprise/overview/about-github-copilot-enterprise).

Learn more about Responsible Use of [GitHub Copilot Chat in your IDE](https://docs.github.com/en/copilot/responsible-use-of-github-copilot-features/responsible-use-of-github-copilot-chat-in-your-ide).
