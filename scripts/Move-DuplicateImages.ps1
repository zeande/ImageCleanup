<#
.SYNOPSIS
Identifies and moves duplicate images from a specified directory to a separate folder for manual review and removal.

.DESCRIPTION
The Move-DuplicateImages cmdlet identifies duplicate images in a specified directory and moves them to a duplicates
folder within the same directory. This allows users to manually review and remove duplicates. The cmdlet uses a
Python script (hash_images.py) to compare images based on their hash values. To save time, the cmdlet only compares
the file with the next few files in the directory, as specified by the lookAhead parameter.

.PARAMETER directoryPath
Specifies the path to the directory containing the images to be checked for duplicates.

.PARAMETER fileExtensions
Specifies an array of file extensions to include in the search. Default is @(".jpg", ".png").

.PARAMETER differenceThreshold
Specifies the threshold for determining whether two images are considered duplicates. Default is 10.

.PARAMETER lookAhead
Specifies the number of subsequent images to compare with the current image. Default is 5.

.PARAMETER deleteDuplicates
If specified, duplicated images will be deleted instead of moved to the duplicates folder while keeping the first image of the duplicates.

.EXAMPLE
Move-DuplicateImages -directoryPath "C:\Photos"
This command identifies and moves duplicated images from the C:\Photos directory to a duplicates folder within the same directory.

.EXAMPLE
Move-DuplicateImages -directoryPath "C:\Photos" -deleteDuplicates
This command deletes duplicate images from the C:\Photos directory.

.EXAMPLE
Move-DuplicateImages -directoryPath "C:\Photos" -fileExtensions @(".jpg", ".png") -differenceThreshold 5 -lookAhead 10
This command moves duplicate images from the C:\Photos directory, including only .jpg and .png files, with a difference threshold of 5 and a look-ahead value of 10.

.NOTES
Using a higher difference threshold may result in false positives when finding duplicates. It is recommended to review the duplicates
before deleting them, but if you are confident in the results, you can use the -deleteDuplicates switch to automatically delete duplicates.

#>
param (
    [Parameter(Mandatory = $true)]
    [string] $directoryPath,
    [string[]] $fileExtensions = @(".jpg", ".png"),
    [int] $differenceThreshold = 10,
    [int] $lookAhead = 5,
    [switch] $deleteDuplicates = $false
)

if (($differenceThreshold -gt 2) -and $deleteDuplicates) {
    Write-Warning "The difference threshold is set to $differenceThreshold. This may result in false positives when deleting duplicates."
    $confirmation = Read-Host "Are you sure you want to proceed? (Y/N)"
    if ($confirmation -ne "Y") {
        Write-Host "Operation cancelled." -ForegroundColor Red
        exit
    }
}

# Create a folder for the duplicates if it doesn't exist
$duplicatesPath = "$directoryPath\duplicates\"
if (-not ((Test-Path -Path $duplicatesPath) -or $deleteDuplicates)) {
    New-Item -ItemType Directory -Path $duplicatesPath
}

# Function to compare images using Python script along with imagehash library
function Compare-Images {
    param (
        [string]$image1,
        [string]$image2
    )

    $result = python.exe "$PSScriptRoot\hash_images.py" $image1 $image2
    return [int]$result
}

$PROGRESS_ACTIVITY_NAME = "Finding duplicates"

# Get all files in the directory that match the specified extensions
$imageFiles = Get-ChildItem -Path $directoryPath -File | Where-Object { $fileExtensions -contains $_.Extension }
$totalFiles = $imageFiles.Count

# Loop through the images and find duplicates
for ($i = 0; $i -lt $imageFiles.Count; $i++) {
    $imageFile = $imageFiles[$i]
    
    if (Test-Path $imageFile.FullName) {
        $duplicateCount = 0
        $difference = 0

        # Update progress
        $percentComplete = [math]::Round(($i / $totalFiles) * 100)
        Write-Progress -Activity $PROGRESS_ACTIVITY_NAME -Status "Processing $($imageFile.Name)" -PercentComplete $percentComplete

        for ($j = 1; ($difference -lt $differenceThreshold) -and ($j -le $lookAhead) -and ($i + $j) -lt $imageFiles.Count; $j++) {
            $nextImageFile = $imageFiles[$i + $j]
            $difference = Compare-Images -image1 $imageFile.FullName -image2 $nextImageFile.FullName

            if ($difference -lt $differenceThreshold) {
                if ($deleteDuplicates) {
                    Remove-Item -Path $nextImageFile.FullName
                } else {
                    Move-Item -Path $nextImageFile.FullName -Destination $duplicatesPath
                }
                
                $duplicateCount++
            }
        }

        # If duplicates were found and duplicates weren't set to be deleted, move the original image as well.
        # This allows the user to review the duplicates before deciding to delete them.
        if (($duplicateCount -gt 0) -and !$deleteDuplicates) {
            Move-Item -Path $imageFile.FullName -Destination $duplicatesPath
        }
    }
}

# Clear the progress bar
Write-Progress -Activity $PROGRESS_ACTIVITY_NAME -Status "Complete" -Completed