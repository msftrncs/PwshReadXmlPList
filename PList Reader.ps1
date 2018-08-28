# parameter to pass input via pipeline
Param(
    [Parameter(Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "XML Plist object.")]
    [ValidateNotNullOrEmpty()]
    [xml]$plist
)

function processTree ($node) {
    $currnode = $node # start at the first node of the node set provided
    $collection = [PSCustomObject]@{}

    <# iterate through the collection of XML nodes provided, recursing through the children nodes to
       extract properties and their values, dictionaries, or arrays of all, but note that property values
       follow their key, not contained within them, and such retrieving the value requires recursing with a 
       clone of the next node.
    #>
    do {
        if ($currnode.HasChildNodes) {
            if ($currnode.Name -eq 'key') {
                # a key in a dictionary, or a single property, either way, add it to a collection
                $collection | Add-member -MemberType NoteProperty -name (processTree $currnode.FirstChild) -value (processTree $currnode.NextSibling.CloneNode($TRUE))
                $currnode = $currnode.NextSibling # skip the next sibling because it was the value of the property
            }
            elseif ($currnode.Name -in 'string', 'array', 'dict') {
                # for string, array, or dict; return the value, with possible recursion and collection
                processTree $currnode.FirstChild
            }
            elseif ($currnode.Name -eq 'integer') {
                # must be an integer type value element, return its value
                processTree $currnode.FirstChild -as [int64]
            }
            elseif ($currnode.Name -eq 'real') {
                # must be a floating type value element, return its value
                processTree $currnode.FirstChild -as [double]
            }
            elseif ($currnode.Name -eq 'date') {
                # must be a date-time type value element, return its value
                processTree $currnode.FirstChild -as [datetime]
            }
            elseif ($currnode.Name -eq 'data') {
                # must be a data block value element, return its value as [byte[]]
                [convert]::FromBase64String((processTree $currnode.FirstChild))
            }
            else {
                # we didn't recognize the element type!
                throw "Unhandled PLIST type '$($currnode.Name)'!"
            }
        }
        else {
            # return simple element value (need to check for Boolean datatype, and process value accordingly)
            if ($currnode.Name -eq 'true') {
                $true # return a Boolean TRUE value
            }
            elseif ($currnode.Name -eq 'false') {
                $false # return a Boolean FALSE value
            }
            else {
                # return the element value
                $currnode.Value
            }
        }
        $currnode = $currnode.NextSibling # move forward to next node.
    } until ($null -eq $currnode) # until no more nodes are left in this set
    # if we built a collection of keys, we need to return the collection, count of object properties doesn't exist until a property is added.
    if ($collection.PSObject.Properties.count) {$collection}
}

# process the 'plist' item of the input XML object
processTree $plist.item("plist").FirstChild
