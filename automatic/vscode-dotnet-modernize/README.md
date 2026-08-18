> ⚠️ **This extension is deprecated.** It has been replaced by
> **[GitHub Copilot upgrade](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.upgrade-agent)**
> (`ms-dotnettools.upgrade-agent`), where all future development continues. **Your existing settings are
> migrated automatically when you install it.** Install the new extension to keep receiving updates and
> improvements.

**GitHub Copilot modernization for .NET** is a public preview AI-powered experience that helps you bring your .NET applications to the latest version quicker and more confidently than ever before. Powered by GitHub Copilot and Agent Mode, it serves as an intelligent upgrade companion that understands your code, determines the right upgrade path, and applies changes step-by-step with minimal manual effort.

## 📋 Prerequisites

- **GitHub Copilot subscription**: If you do not have a subscription, you can get one here: [Get access to Copilot](https://docs.github.com/en/copilot/get-started/what-is-github-copilot#getting-access-to-copilot)
- **Repository**: Git-based repositories only  
- **Project Targets**: .NET Core 3.x, .NET 5, .NET 6, .NET 7, or .NET 8  

## 🚀 What’s Included

- **Intelligent upgrade plan generation**  
  The tool analyzes your solution and generates a dependency-aware plan that upgrades projects in the right order.

- **Automated code transformations**  
  Copilot automatically makes the changes required to get your applications running on modern .NET.

- **Customizable workflows**  
  You can tailor which projects to upgrade, whether to address packages with security vulnerabilities in your upgrade, and more.

- **Learning from your manual interventions**  
  When manual intervention is required, the tool can learn from your manual changes and apply those learnings if it encounters a similar situation later on.

- **Git integration**  
  Git commits are automatically created on your behalf so that you can adopt and test changes incrementally.

- **Automatic test validation**  
  The tool automatically runs your application’s unit tests to ensure correct behavior post-upgrade.

- **Agent Mode functionality**  
  Take advantage of Copilot Agent Mode with the latest preview version of Visual Studio installed.


## 🛠️ Getting Started

### Install the Extension

Download the **GitHub Copilot modernization for .NET** extension from the Visual Studio Code Marketplace. Once installed, you’re ready to use the tool.

## ⚙️ How to Run the Upgrade

1. Open the **Copilot Chat** window
2. Select the **Modernize** custom agent from the agent picker
3. Tell Copilot what you want to do, for example: "Upgrade my solution to a new version of .NET"

That's it! The tool will analyze your code, prepare the upgrade, and help Copilot guide you through the required code changes.

## Supported Upgrade Paths

- .NET Core 3.x, 5, 6, or 7 → .NET 8, .NET 9 or .NET 10

## 💬 Share Feedback

Your feedback is essential as we improve during public preview. Share your thoughts [here](https://github.com/microsoft/github-copilot-appmod/issues/new?template=feedback-template.yml) to help shape the product.

---

## License

This extension is licensed under [GitHub Copilot Product Specific Terms](https://github.com/customer-terms/github-copilot-product-specific-terms).

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.

## Privacy statement

Modernization for .NET uses GitHub Copilot just like how you modify code with GitHub Copilot, which does not retain code snippets beyond the immediate session. We do not collect, transmit or store your custom tasks either. Please review the [Microsoft Privacy Statement](https://go.microsoft.com/fwlink/?LinkId=521839) if necessary.
