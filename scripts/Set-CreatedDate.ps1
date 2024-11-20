<#
.SYNOPSIS
Updates the 'Date Created' and 'Date Modified' metadata of files based on the 'Date Taken' property of the image or the
date in the filename.

.DESCRIPTION
The Set-CreatedDate cmdlet updates the 'Date Created' and 'Date Modified' properties of the files in a specified
directory. It first tries to get the date from the 'Date Taken' property of the image. If this property is not
available, it attempts to parse the date from the filename.

.PARAMETER directoryPath
Specifies the path to the directory containing the images to be updated.

.PARAMETER fileExtensions
Specifies an array of file extensions to include in the search. Default is @(".jpg", ".png").

.EXAMPLE
Set-CreatedDate -directoryPath "C:\Photos"
This command updates the 'Date Created' and 'Date Modified' metadata of images in the C:\Photos directory.

.EXAMPLE
Set-CreatedDate -directoryPath "C:\Photos" -fileExtensions @(".jpg", ".png")
This command updates the 'Date Created' and 'Date Modified' metadata of .jpg and .png images in the C:\Photos directory.

.NOTES
The cmdlet uses the 'Date Taken' property of the image if available. If not, it attempts to parse the date from the
filename using the format 'yyyyMMdd_HHmmss'.

This script is important for organizing images based on their actual creation date. If this step is skipped, the images
may not be sorted correctly when viewing them in your target cloud storage or photo management application.
#>
param (
    [Parameter(Mandatory = $true)]
    [string] $directoryPath,
    [string[]] $fileExtensions = @(".jpg", ".png")
)

# Get all files in the directory that match the specified extensions
$files = Get-ChildItem -Path $directoryPath -File | Where-Object { $fileExtensions -contains $_.Extension }
$updatedCount = 0

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
        $updatedCount
    }
}

Write-Host "$updatedCount files were updated." -ForegroundColor Green