# PwshReadXmlPList

PwshReadXmlPList is a project to process an XML PList document into a usable PowerShell object.  The resulting object will depend on the PList document, but will commonly be composed of ordered dictionaries and/or arrays of common (basic) value types or further dictionaries or arrays.

An XML PList is a somewhat challenging document to process due to a lack of wrapping each dictionary (`<dict>`) item's key (`<key>`) and value in a separate node tree, requiring sequential sibling node processing.

## ConvertFrom-Plist

The project provides one function, `ConvertFrom-Plist` to process an XML PList document as a pipeline input.  You use typical PowerShell processes to read in the XML content of the PList, whether from a file or other sources, using the `[xml]` shortcut to convert the content to an XML object if not already sourced as such, prior to piping to `ConvertFrom-Plist`.

### Parameters
- plist (`-plist`)

  The parameter `-plist` may be used in place of pipeline input.

### Examples

Example uses:
```powershell
. '.\PList Reader.ps1' # import the ConvertFrom-Plist function to the current session
$pList = ConvertFrom-Plist -plist ([xml](Get-Content 'somefile.plist')) # read 'somefile.plist' file and convert the result to $pList
$grammar_plist = [xml](Get-Content PowerShellSyntax.tmLanguage) | ConvertFrom-Plist # read the PowerShell TextMate syntax grammar description file and convert the result to $grammar_plist
```

### Handling of `<data>`

ConvertFrom-Plist handles PList `<data>` objects by preparing them into byte array (`[byte[]]`) objects.  The data that is encoded in the byte arrays depends on the application that generated the PList document.  You may need to provide further processing for these objects.

### Notes
- PowerShell scripting knowledge is required.
- This project was initially created to aid in processing TextMate tmLanguage grammar files, primarily for conversion to other formats, such as JSON.
- `<key>` is not currently handled at the root level, but this appears to be compliant with the XML PList DTD.
