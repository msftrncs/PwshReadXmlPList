# parameter to pass input via pipeline
function ConvertFrom-Plist {
    Param(
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
            $currnode = $node # start at the first node of the node set provided
            $collection = [ordered]@{}

            <# iterate through the collection of XML nodes provided, recursing through the children nodes to
            extract properties and their values, dictionaries, or arrays of all, but note that property values
            follow their key, not contained within them, and such retrieving the value requires recursing with a 
            clone of the next node.
            #>
            do {
                if ($currnode.HasChildNodes) {
                    if ($currnode.Name -eq 'key') {
                        # a key in a dictionary, or a single property, either way, add it to a collection
                        $collection += [ordered]@{ [plistreader]::processTree($currnode.FirstChild) = [plistreader]::processTree($currnode.NextSibling.CloneNode($true)) }
                        $currnode = $currnode.NextSibling # skip the next sibling because it was the value of the property
                    }
                    elseif ($currnode.Name -in 'string', 'dict') {
                        # for string, or dict; return the value, with possible recursion and collection
                        return [plistreader]::processTree($currnode.FirstChild)
                    }
                    elseif ($currnode.Name -eq 'array' ) {
                        # for arrays, recurse the tree, and always return the array 
                        return @(foreach ($sibling in $currnode.ChildNodes) {[plistreader]::processTree($sibling.CloneNode($true))})
                    }
                    elseif ($currnode.Name -eq 'integer') {
                        # must be an integer type value element, return its value
                        return [plistreader]::processTree($currnode.FirstChild) | ForEach-Object {
                            # try to determine what size of interger to return this value as 
                            if ([int]::TryParse( $_, [ref] $null)) {
                                # a 32bit integer seems to work
                                $_ -as [int]
                            }
                            else {
                                if ([int64]::TryParse( $_, [ref] $null)) {
                                    # a 64bit integer seems to be needed
                                    $_ -as [int64]
                                }
                                else {
                                    # try an unsigned 64bit interger, the largest available here.
                                    $_ -as [uint64]
                                }
                            }
                        }
                    }
                    elseif ($currnode.Name -eq 'real') {
                        # must be a floating type value element, return its value
                        return [plistreader]::processTree($currnode.FirstChild) -as [double]
                    }
                    elseif ($currnode.Name -eq 'date') {
                        # must be a date-time type value element, return its value
                        return [plistreader]::processTree($currnode.FirstChild) -as [datetime]
                    }
                    elseif ($currnode.Name -eq 'data') {
                        # must be a data block value element, return its value as [byte[]]
                        return [convert]::FromBase64String([plistreader]::processTree($currnode.FirstChild))
                    }
                    else {
                        # we didn't recognize the element type!
                        throw "Unhandled PLIST type '$($currnode.Name)'!"
                    }
                }
                else {
                    # return simple element value (need to check for Boolean datatype, and process value accordingly)
                    if ($currnode.Name -eq 'true') {
                        return $true # return a Boolean TRUE value
                    }
                    elseif ($currnode.Name -eq 'false') {
                        return $false # return a Boolean FALSE value
                    }
                    else {
                        # return the element value
                        return $currnode.Value
                    }
                }
                $currnode = $currnode.NextSibling # move forward to next node.
            } until ($null -eq $currnode) # until no more nodes are left in this set
            # if we built a collection of keys, we need to return the collection, count of object properties doesn't exist until a property is added.
            return $collection
        }
    }

    # process the 'plist' item of the input XML object
    [plistreader]::processTree($plist.item('plist').FirstChild)
}