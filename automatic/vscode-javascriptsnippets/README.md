# JavaScript
## VS Code JavaScript (ES6) snippets
-------------------

[![Version](https://vsmarketplacebadge.apphb.com/version/xabikos.JavaScriptSnippets.svg)](https://marketplace.visualstudio.com/items?itemName=xabikos.JavaScriptSnippets)
[![Installs](https://vsmarketplacebadge.apphb.com/installs/xabikos.JavaScriptSnippets.svg)](https://marketplace.visualstudio.com/items?itemName=xabikos.JavaScriptSnippets)
[![Ratings](https://vsmarketplacebadge.apphb.com/rating/xabikos.JavaScriptSnippets.svg)](https://marketplace.visualstudio.com/items?itemName=xabikos.JavaScriptSnippets)

This extension contains code snippets for JavaScript in ES6 syntax for [Vs Code][code] editor (supports both JavaScript and TypeScript).

### Note
**All the snippets include the final semicolon `;` There is a fork of those snippets [here](https://marketplace.visualstudio.com/items?itemName=jmsv.JavaScriptSnippetsStandard)
made by @jmsv where semicolons are not included. So feel free to use them according to your needs.**

## Sponsors
<p><a title="Try CodeStream" href="https://sponsorlink.codestream.com/?utm_source=vscmarket&amp;utm_campaign=jses6codesnippets&amp;utm_medium=banner"><img src="https://alt-images.codestream.com/codestream_logo_jses6codesnippets.png"></a></br>
Request and perform code reviews from inside your IDE.  Review any code, even if it's a work-in-progress that hasn't been committed yet, and use jump-to-definition, your favorite keybindings, and other IDE tools.<br> <a title="Try CodeStream" href="https://sponsorlink.codestream.com/?utm_source=vscmarket&amp;utm_campaign=jses6codesnippets&amp;utm_medium=banner">Try it free</a></p>


## Installation

In order to install an extension you need to launch the Command Palette (Ctrl + Shift + P or Cmd + Shift + P) and type Extensions.
There you have either the option to show the already installed snippets or install new ones. Search for *JavaScript (ES6) code snippets* and install it.

## Supported languages (file extensions)
* JavaScript (.js)
* TypeScript (.ts)
* JavaScript React (.jsx)
* TypeScript React (.tsx)
* Html (.html)
* Vue (.vue)

## Snippets

Below is a list of all available snippets and the triggers of each one. The **â‡¥** means the `TAB` key.

### Import and export
| Trigger  | Content |
| -------: | ------- |
| `impâ†’`   | imports entire module `import fs from 'fs';`|
| `imnâ†’`   | imports entire module without module name `import 'animate.css'` |
| `imdâ†’`   | imports only a portion of the module using destructing  `import {rename} from 'fs';` |
| `imeâ†’`   | imports everything as alias from the module `import * as localAlias from 'fs';` |
| `imaâ†’`   | imports only a portion of the module as alias `import { rename  as localRename } from 'fs';` |
| `rqrâ†’`   | require package `require('');`|
| `reqâ†’`   | require package to const `const packageName = require('packageName');`|
| `mdeâ†’`   | default module.exports `module.exports = {};`|
| `envâ†’`   | exports name variable `export const nameVariable = localVariable;` |
| `enfâ†’`   | exports name function `export const log = (parameter) => { console.log(parameter);};` |
| `edfâ†’`   | exports default function `export default function fileName (parameter){ console.log(parameter);};` |
| `eclâ†’`   | exports default class `export default class Calculator { };` |
| `eceâ†’`   | exports default class by extending a base one `export default class Calculator extends BaseClass { };` |

### Class helpers
| Trigger  | Content |
| -------: | ------- |
| `conâ†’`   | adds default constructor in the class `constructor() {}`|
| `metâ†’`   | creates a method inside a class `add() {}` |
| `pgeâ†’`   | creates a getter property `get propertyName() {return value;}` |
| `pseâ†’`   | creates a setter property `set propertyName(value) {}` |

### Various methods
| Trigger  | Content |
| -------: | ------- |
| `freâ†’`   | forEach loop in ES6 syntax `array.forEach(currentItem => {})`|
| `fofâ†’`   | for ... of loop `for(const item of object) {}` |
| `finâ†’`   | for ... in loop `for(const item in object) {}` |
| `anfnâ†’`  | creates an anonymous function `(params) => {}` |
| `nfnâ†’`   | creates a named function `const add = (params) => {}` |
| `dobâ†’`   | destructing object syntax `const {rename} = fs` |
| `darâ†’`   | destructing array syntax `const [first, second] = [1,2]` |
| `stiâ†’`   | set interval helper method `setInterval(() => {});` |
| `stoâ†’`   | set timeout helper method `setTimeout(() => {});` |
| `promâ†’`  | creates a new Promise `return new Promise((resolve, reject) => {});`|
| `thencâ†’` | adds then and catch declaration to a promise `.then((res) => {}).catch((err) => {});`|

### Console methods
| Trigger  | Content |
| -------: | ------- |
| `casâ†’`   | console alert method `console.assert(expression, object)`|
| `cclâ†’`   | console clear `console.clear()` |
| `ccoâ†’`   | console count `console.count(label)` |
| `cdbâ†’`   | console debug `console.debug(object)` |
| `cdiâ†’`   | console dir `console.dir` |
| `cerâ†’`   | console error `console.error(object)` |
| `cgrâ†’`   | console group `console.group(label)` |
| `cgeâ†’`   | console groupEnd `console.groupEnd()` |
| `clgâ†’`   | console log `console.log(object)` |
| `cloâ†’`   | console log object with name `console.log('object :>> ', object);` |
| `ctrâ†’`   | console trace `console.trace(object)` |
| `cwaâ†’`   | console warn `console.warn` |
| `cinâ†’`   | console info `console.info` |
| `cltâ†’`   | console table `console.table` |
| `ctiâ†’`   | console time `console.time` |
| `cteâ†’`   | console timeEnd `console.timeEnd` |

[code]: https://code.visualstudio.com/
