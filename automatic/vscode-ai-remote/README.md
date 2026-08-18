# Azure Machine Learning - Remote Extension

This extension is complementary to the [Azure Machine Learning](https://aka.ms/aml-ext-get-started) extension and is used to seamlessly connect VS Code to a remote Compute Instance.

Once connected to the compute instance, you can:

-   Run and debug Python scripts and Notebooks, executing directly on the CI
-   Traverse the remote filesystem and mounted fileshare
-   Invoke commands in a remote terminal
-   Clone and manage git repos

![Remote Extension Gif](https://raw.githubusercontent.com/microsoft/vscode-tools-for-ai/master/media/remote_extension_readme/remote_extension_demo.gif)

### Quick Start

1. Navigate to the Azure Machine Learning Studio (ml.azure.com).

2. Invoke the VS Code "click-out" link from either the Notebook or Compute tabs.
   a. [Compute] The VS Code button is in line with your listed compute instances.

    ![Compute Tab Entrypoint](https://raw.githubusercontent.com/microsoft/vscode-tools-for-ai/master/media/remote_extension_readme/compute_link.png)

    b. [Notebook] Click on the "Editors" dropdown and choose the "Edit in VS Code" option.

    ![Notebook Tab Entrypoint](https://raw.githubusercontent.com/microsoft/vscode-tools-for-ai/master/media/remote_extension_readme/notebook_link.png)

3. Once you land in VS Code, you'll be prompted to install the Azure ML extension if you do not already have it. If you have an older version of the extension (0.6.17 or less), please upgrade to the latest version and Try Again.

4. The Azure Machine Learning - Remote extension will be used to set up your connection. After invoking the connection from the Studio UI the first time, subsequent connections can be invoked within VS Code using the "Azure ML: Connect to Compute Instance" command.

![VS Code Entrypoint](https://raw.githubusercontent.com/microsoft/vscode-tools-for-ai/master/media/remote_extension_readme/code_entrypoint.jpg)

### Useful Commands

Open the Command Palette (Command+Shift+P on macOS and Ctrl+Shift+P on Windows/Linux) and type in one of the following commands:

| Command                                                      | Description                                                                           |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| Azure ML: Connect to Compute Instance                        | Connect to a compute instance in your Azure Machine Learning workspace                |
| Azure ML: Kill VS Code server on Compute Instance            | Stop the running remote VS Code server. Useful when troubleshooting connection issues |
| Azure ML: Kill Azure ML websocket server on Compute Instance | Stop the running websocket server                                                     |

### Questions, issues, feature requests

-   Any and all feedback is appreciated and welcome! If you come across a problem with the extension please [file an issue](https://github.com/microsoft/vscode-tools-for-ai/issues/new/choose).
-   If you'd like to provide feedback for the extension, [please fill out this survey](https://aka.ms/aml-ext-survey).

### Data and Telemetry

The Azure Machine Learning - Remote Extension for Visual Studio Code collects usage data and sends it to Microsoft to help improve our products and services. Read our [privacy statement](https://privacy.microsoft.com/privacystatement) to learn more. This extension respects the telemetry.enableTelemetry setting which you can learn more about [here](https://code.visualstudio.com/docs/supporting/faq#_how-to-disable-telemetry-reporting).
