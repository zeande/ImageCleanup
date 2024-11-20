param (
    [Parameter(Mandatory = $true)]
    [string] $directoryPath,
    [string[]] $fileExtensions = @(".jpg", ".png")
)

# Get all files in the directory that match the specified extensions
$files = Get-ChildItem -Path $directoryPath -File | Where-Object { $fileExtensions -contains $_.Extension }

foreach ($file in $files) {
    # Load the image
    $image = [System.Drawing.Image]::FromFile($file.FullName)

    # Try to get the date from the image properties
    $takenDate = $null
    if ($image.PropertyIdList -contains 36867) {
        $propertyValue = $image.GetPropertyItem(36867).Value
        $dateAsString = [System.Text.Encoding]::ASCII.GetString($propertyValue)
        $takenDate = [DateTime]::ParseExact($dateAsString, "yyyy:MM:dd HH:mm:ss`0", $null)
    }
    
    $image.Dispose()

    if (!$takenDate) {
        # Otherwise, try to parse the date from the file name
        if ($file.Name -match "\d{8}_\d{6}") {
            $dateString = $matches[0]
            $takenDate = [datetime]::ParseExact($dateString, "yyyyMMdd_HHmmss", $null)
        }
    }
        
    if ($takenDate) {
        $file.LastWriteTime = $takenDate
        $file.CreationTime = $takenDate
    }
}