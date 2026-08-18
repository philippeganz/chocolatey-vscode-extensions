# GitHub Copilot upgrade

Upgrade and migrate your projects with GitHub Copilot in Visual Studio Code.
The GitHub Copilot upgrade extension adds an **Upgrade** agent to Copilot Chat
that can inspect your workspace, recommend an upgrade path, guide required
choices, and help you work through upgrade tasks step by step.

This release includes built-in support for .NET and JavaScript/TypeScript upgrade and migration scenarios.
The GitHub Copilot upgrade plugin is also available from
[microsoft/upgrade-agent-plugins](https://github.com/microsoft/upgrade-agent-plugins).

## Getting started

1. Install GitHub Copilot Chat and sign in with an account that can use Copilot.
2. Install **GitHub Copilot upgrade**.
3. Open the project or solution you want to upgrade in VS Code.
4. Open Copilot Chat and select the **Upgrade** agent.
5. Ask for the upgrade you want, such as:
    - `Upgrade my solution to .NET 10`
    - `Upgrade my project to TypeScript 7`
    - `Migrate this .NET Framework app to modern .NET`
    - `Move this Web Forms app to Blazor Server`
    - `Upgrade my Azure Functions project to the isolated worker model`
    - `Replace Newtonsoft.Json with System.Text.Json`
6. Follow the agent's prompts, review proposed changes, and run the validation
   steps it recommends.

You can also start from the `@upgrade` chat participant. It forwards your
prompt to the Upgrade agent.

## What it can help with

This release includes built-in support for these .NET upgrade scenarios:

| Scenario | Use it when you want to... | Example prompt |
|---|---|---|
| .NET version upgrade | Move .NET Framework, .NET Core, or older .NET projects to a current supported .NET version such as .NET 8, .NET 9, .NET 10, or later targets as they become available. | `Upgrade my solution to .NET 10` |
| .NET Framework version upgrade | Stay on full .NET Framework while moving projects to .NET Framework 4.8.1. | `Upgrade this app to .NET Framework 4.8.1` |
| ASP.NET Web Forms to Blazor | Modernize ASP.NET Web Forms applications by moving pages and UI patterns toward Blazor Server. | `Move this Web Forms app to Blazor Server` |
| Azure Functions upgrade | Move Azure Functions projects from the in-process model to the isolated worker model. | `Upgrade my Azure Functions project to isolated worker` |
| Aspire integration | Add Aspire orchestration to an existing .NET solution for local development and optional Azure readiness. | `Add Aspire to this solution` |
| Aspire version upgrade | Upgrade projects that already use Aspire to a newer Aspire version, including required .NET target framework and package updates. | `Upgrade my Aspire project to the latest version` |
| SDK-style project conversion | Convert older C# or Visual Basic project files to modern SDK-style format. | `Convert these projects to SDK-style` |
| Visual Studio extension project conversion | Modernize Visual Studio extension projects that use legacy VSIX or VSSDK project formats. | `Convert this VSIX project to SDK-style` |
| Newtonsoft.Json migration | Replace Newtonsoft.Json usage with System.Text.Json where appropriate. | `Replace Newtonsoft.Json with System.Text.Json` |
| SqlClient migration | Move SQL Server data access from System.Data.SqlClient to Microsoft.Data.SqlClient. | `Update this app to use Microsoft.Data.SqlClient` |
| Semantic Kernel agents migration | Move Semantic Kernel agent code to the Microsoft Agents framework. | `Migrate my Semantic Kernel agents` |

The agent analyzes your workspace, identifies relevant upgrade work, breaks it
into reviewable tasks, and helps you continue or resume progress over time. It
can also work with additional language or platform extenders when they are
installed.

## Requirements

- Visual Studio Code with GitHub Copilot Chat installed.
- A signed-in GitHub Copilot account.
- A workspace containing the project or solution you want to upgrade.
- Network access to acquire and run the upgrade tools from NuGet.

The extension uses the .NET Install Tool for Extension Authors to locate or
acquire the .NET SDK required to run the upgrade tools. You normally do not need
to install that SDK manually.

## Settings

The extension contributes these settings under **GitHub Copilot upgrade**:

- `copilotUpgrade.allowPrerelease`: allow prerelease versions of the upgrade
  tools. Disabled by default (stable versions are used).
- `copilotUpgrade.version`: use a specific upgrade tool version. When set, this
  takes precedence over `copilotUpgrade.allowPrerelease`.
- `copilotUpgrade.nugetSource`: use a custom NuGet feed source for the upgrade
  tools.

## Troubleshooting

If the Upgrade agent is not available, confirm that GitHub Copilot Chat is
installed and signed in, then reload the VS Code window.

If the extension cannot start the upgrade tools, check that VS Code can access
NuGet and that your configured `copilotUpgrade.nugetSource`, if any, is
reachable.

For MCP server logs, run **MCP: List Servers** from the Command Palette, select
`Upgrade`, and choose **Show Output**. The **Copilot upgrade for .NET** Output
channel shows extension startup and extender discovery messages.

To file an issue, use
[microsoft/upgrade-agent-plugins](https://github.com/microsoft/upgrade-agent-plugins/issues/new).

## Privacy

GitHub Copilot upgrade uses GitHub Copilot to help modify code in your current
workspace. It does not retain code snippets beyond the immediate session and
does not collect, transmit, or store your custom tasks. See the
[Microsoft Privacy Statement](https://go.microsoft.com/fwlink/?LinkId=521839)
for more information.

## License

This extension is licensed under the
[GitHub Copilot Product Specific Terms](https://github.com/customer-terms/github-copilot-product-specific-terms).

## Trademarks

This project may contain trademarks or logos for projects, products, or
services. Authorized use of Microsoft trademarks or logos is subject to and must
follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Any use of third-party trademarks or logos is subject to those third-party
policies.
