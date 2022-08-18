# ps-md-include
Include other files (like code) in Markdown

## Requirement
PowerShell 6 or Higher

## Usage
1. Insert a `md_include` block in your Markdown file.
```
# test
<!-- #md_include "Program.cs" from 1 to 3 as code lang csharp -->
<!-- #md_include end -->
```
2. Run Sync-MarkdownInclude.ps1 with PowerShell in your Markdown file folder.
3. You will got csharp code in your Markdown file.
````
# test
<!-- #md_include "Program.cs" from 1 to 3 as code lang csharp -->
```csharp
using System;
using System.Linq;
```
<!-- #md_include end -->
````
## Parameters
1. "Program.cs": a relative path of a text file or source file.
2. from {number}: line number where start to read file. (default is 1, not required, should use with `to`)
3. to {number}: line number where start to read file. (default is end line number, not required, should use with `from`)
4. as {type}: type for render a block. raw type will give raw text. code type will give text with a code block. (default is raw, not required)
5. lang {lang}: programing language for code block. (default is nul, not required, should use with `as code`)
