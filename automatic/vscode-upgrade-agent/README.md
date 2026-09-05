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

This release includes built-in support for these upgrade scenarios:

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
| PowerShell 5.1 to 7 upgrade | Move Windows PowerShell 5.1 scripts, modules, and manifests — build, deploy, and operations automation — to cross-platform PowerShell 7. | `Upgrade my PowerShell scripts to PowerShell 7` |

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

### What is sent to GitHub Copilot

GitHub Copilot upgrade works through GitHub Copilot to analyze and modify code in
your current workspace. To do that, the Upgrade agent and its tools include
workspace content in your Copilot requests. Depending on the scenario and the
step you are on, that content can include:

- **Workspace identifiers** — file, project, and solution paths.
- **Source code** — contents and code snippets from the files being analyzed or
  changed, and from project and configuration files such as `.csproj`, `.sln`,
  `package.json`, and `Directory.Packages.props`.
- **Dependency and framework data** — package names and versions, project
  references, and current and target framework versions.
- **Build and validation output** — restore, build, analyzer, and test results,
  including compiler errors, warnings, diagnostic IDs, and failure messages.
- **Prompts, instructions, and upgrade workspace** — your chat prompts and
  instructions; the generated assessment, `plan.md`, `tasks.md`, and per-task
  files under `tasks/{taskId}/`, including any edits you make to them; and
  preferences and instructions in `scenario-instructions.md`. These files are
  written only to your repository under `.github/upgrades/`. The extension does
  not independently upload or store them elsewhere, but the agent reads them
  while working and when resuming, so their contents may be included in GitHub
  Copilot requests.

This content is handled as part of your GitHub Copilot requests, subject to the
[GitHub General Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).
For details on how Copilot handles prompts and retention, see the
[GitHub Copilot Trust Center](https://copilot.github.trust.page/).

### Telemetry

The extension and the upgrade tools it starts collect usage telemetry: anonymous
session and device identifiers, product and environment versions, the selected
upgrade scenario, aggregate workspace metrics, upgrade progress and timing, and
diagnostic identifiers such as compiler error and analysis rule IDs.

Telemetry does not include source code or file contents. Diagnostics are reduced
to identifiers and counts rather than message text, and repository URLs and
names and any reported paths are hashed before they are sent.

This extension respects the VS Code `telemetry.telemetryLevel` setting; setting
it to `off` disables telemetry for both the extension and the upgrade tools it
starts. See the
[Microsoft Privacy Statement](https://go.microsoft.com/fwlink/?LinkId=521839)
for more information.

### Other network activity

The extension downloads the upgrade tools from nuget.org, or from the feed you
configure in `copilotUpgrade.nugetSource`, and may use the .NET Install Tool for
Extension Authors to acquire the required .NET SDK.

## License

This extension is licensed under the
[GitHub Copilot Product Specific Terms](https://github.com/customer-terms/github-copilot-product-specific-terms).

## Trademarks

This project may contain trademarks or logos for projects, products, or
services. Authorized use of Microsoft trademarks or logos is subject to and must
follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Any use of third-party trademarks or logos is subject to those third-party
policies.
