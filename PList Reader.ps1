<#
.SYNOPSIS
    Convert a XML Plist to a PowerShell object
.DESCRIPTION
    Converts an XML PList (property list) in to a usable object in PowerShell.
.EXAMPLE
    $pList = [xml](get-content 'somefile.plist') | ConvertFrom-Plist
.INPUTS
    plist - as an [XML] object containing the PList
.OUTPUTS
    [object] - containing the PList as conventional PowerShell object types, hashtables, arrays, strings, numeric values, and byte arrays.
.NOTES
    Script / Function / Class assembled by Carl Morris, Morris Softronics, Hooper, NE, USA
    Initial release - Aug 27, 2018
.LINK
    https://github.com/msftrncs/PwshReadXmlPList
.FUNCTIONALITY
    data format conversion
#>
function ConvertFrom-Plist {
    Param(
        # parameter to pass input via pipeline
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'XML Plist object.')]
        [ValidateNotNullOrEmpty()]
        [xml]$plist
    )

    # define a class to provide a method for accelerated processing of the XML tree
    class plistreader {
        # define a static method for accelerated processing of the XML tree
        static [object] processTree ($node) {
            return $(
                <#  iterate through the collection of XML nodes provided, recursing through the children nodes to
                extract properties and their values, dictionaries, or arrays of all, but note that property values
                follow their key, not contained within them. #>
                if ($node.HasChildNodes) {
                    switch ($node.Name) {
                        dict {
                            # for dictionary, return the subtree as a hashtable, with possible recursion of additional arrays or dictionaries
                            $collection = [ordered]@{}
                            $currnode = $node.FirstChild # start at the first child node of the dictionary
                            while ($null -ne $currnode) {
                                if ($currnode.Name -eq 'key') {
                                    # a key in a dictionary, add it to a collection
                                    if ($null -ne $currnode.NextSibling) {
                                        $collection.Add([plistreader]::processTree($currnode.FirstChild), [plistreader]::processTree($currnode.NextSibling))
                                        $currnode = $currnode.NextSibling.NextSibling # skip the next sibling because it was the value of the property
                                    }
                                    else {
                                        throw "Dictionary property value missing!"
                                    }
                                }
                                else {
                                    throw "Non 'key' element found in dictionary: <$($currnode.Name)>!"
                                }
                            }
                            # return the collected hash table
                            $collection
                            continue
                        }
                        array {
                            # for arrays, recurse each node in the subtree, returning an array (forced)
                            , @(foreach ($sibling in $node.ChildNodes) {[plistreader]::processTree($sibling)})
                            continue
                        }
                        string {
                            # for string, return the value, with possible recursion and collection
                            [plistreader]::processTree($node.FirstChild)
                            continue
                        }
                        integer {
                            # must be an integer type value element, return its value
                            [plistreader]::processTree($node.FirstChild) | ForEach-Object {
                                # try to determine what size of interger to return this value as
                                if ([int]::TryParse( $_, [ref]$null)) {
                                    # a 32bit integer seems to work
                                    $_ -as [int]
                                }
                                else {
                                    if ([int64]::TryParse( $_, [ref]$null)) {
                                        # a 64bit integer seems to be needed
                                        $_ -as [int64]
                                    }
                                    else {
                                        # try an unsigned 64bit interger, the largest available here.
                                        $_ -as [uint64]
                                    }
                                }
                            }
                            continue
                        }
                        real {
                            # must be a floating type value element, return its value
                            [plistreader]::processTree($node.FirstChild) -as [double]
                            continue
                        }
                        date {
                            # must be a date-time type value element, return its value
                            [plistreader]::processTree($node.FirstChild) -as [datetime]
                            continue
                        }
                        data {
                            # must be a data block value element, return its value as [byte[]]
                            [convert]::FromBase64String([plistreader]::processTree($node.FirstChild))
                            continue
                        }
                        default {
                            # we didn't recognize the element type!
                            throw "Unhandled PLIST property type <$($node.Name)>!"
                        }
                    }
                }
                else {
                    # return simple element value (need to check for Boolean datatype, and process value accordingly)
                    switch ($node.Name) {
                        true {$true; continue} # return a Boolean TRUE value
                        false {$false; continue} # return a Boolean FALSE value
                        default {$node.Value} # return the element value
                    }
                }
            )
        }
    }

    # process the 'plist' item of the input XML object
    [plistreader]::processTree($plist.item('plist').FirstChild)
}