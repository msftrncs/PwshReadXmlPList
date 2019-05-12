# PwshReadXmlPList

PowerShell function to process an XML PList file in to a meaningful object.  The entire PList will be a single custom object, which can then be further manipulated within PowerShell.

Within it is a fairly complete XML PList reading function.  The XML PList is a poorly constructed XML document, due to its &lt;dict&gt; items not being individually stored in separate 'property' child nodes.

The script presently accepts input of an XML object which it can accept from the pipeline.  Use the \[xml\] shortcut to read the document:

```powershell
. '.\PList Reader.ps1'
$pList = [xml](get-content 'somefile.plist') | ConvertFrom-Plist
$grammar_plist = [xml](Get-Content PowerShellSyntax.tmLanguage) | ConvertFrom-Plist
```

Note:
- This function was initially developed to aid in processing TextMate tmLanguage grammar files.
- There is a possibility that not all PLIST documents can be handled at this time.  `<key>` is not currently handled at the root level.
