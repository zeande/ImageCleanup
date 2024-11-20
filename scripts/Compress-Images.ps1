<#
.SYNOPSIS
This script compresses (downscales) images in the specified directory.

.PARAMETER direcotryPath
Specifies the path to the directory containing the images to compress.

.PARAMETER maxDimension
Specifies the maximum dimension (width or height) for the compressed images. Default is 2048.

.PARAMETER fileExtensions
Specifies the file extensions to include in the compression process. Default is ".jpg" and ".png".

.EXAMPLE
.\Compress-Images.ps1 -directoryPath "~/Downloads/Images" -maxDimension 1024 -fileExtensions @(".jpg")
This example compresses all JPEG images in the "~/Downloads/Images" directory to a maximum dimension of 1024 pixels.
#>
param (
    [Parameter(Mandatory = $true)]
    [string] $directoryPath,
    [int] $maxDimension = 2048,
    [string[]] $fileExtensions = @(".jpg", ".png")
)

# Define the path to the downscaled images
$downscaledPath = "$directoryPath\downscaled\"
if (-not (Test-Path -Path $downscaledPath)) {
    New-Item -ItemType Directory -Path $downscaledPath
}

# Load the required .NET assembly
Add-Type -AssemblyName System.Drawing

# Get all image files in the directory
$imageFiles = Get-ChildItem -Path $directoryPath -File | Where-Object { $fileExtensions -contains $_.Extension }

$PROGRESS_ACTIVITY_NAME = "Processing images"

$currentFileIndex = 0
$totalFiles = $imageFiles.Count

foreach ($imageFile in $imageFiles) {
    $currentFileIndex++
    $percentComplete = [math]::Round(($currentFileIndex / $totalFiles) * 100)
    
    # Update progress
    Write-Progress -Activity $PROGRESS_ACTIVITY_NAME -Status "Processing $($imageFile.Name)" -PercentComplete $percentComplete
    
    # Load the image
    $image = [System.Drawing.Image]::FromFile($imageFile.FullName)
    
    # Calculate the new dimensions while preserving the aspect ratio
    if ($image.Width -gt $maxDimension -or $image.Height -gt $maxDimension) {
        if ($image.Width -gt $image.Height) {
            $newWidth = $maxDimension
            $newHeight = [math]::Round($image.Height * ($maxDimension / $image.Width)) -as [int]
        } else {
            $newHeight = $maxDimension
            $newWidth = [math]::Round($image.Width * ($maxDimension / $image.Height)) -as [int]
        }

        # Create a new bitmap with the new dimensions
        $newImage = New-Object System.Drawing.Bitmap $newWidth, $newHeight
        $graphics = [System.Drawing.Graphics]::FromImage($newImage)
        $graphics.DrawImage($image, 0, 0, $newWidth, $newHeight)

        # Copy metadata from the original image to the new image
        foreach ($property in $image.PropertyItems) {
            $newImage.SetPropertyItem($property)
        }

        # Save the new image
        $newFilePath = Join-Path -Path $downscaledPath -ChildPath ($imageFile.Name)
        $newImage.Save($newFilePath, $image.RawFormat)

        # Set the original file's last write time to the new file
        $newImageFile = Get-Item $newFilePath
        $newImageFile.LastWriteTime = $imageFile.LastWriteTime
        $newImageFile.CreationTime = $imageFile.CreationTime

        # Dispose of the objects
        $graphics.Dispose()
        $newImage.Dispose()
    } else {
        # If the image is already smaller than the maximum dimension, copy it as is
        Copy-Item $imageFile $downscaledPath
    }

    # Dispose of the original image
    $image.Dispose()
}

# Clear the progress bar
Write-Progress -Activity $PROGRESS_ACTIVITY_NAME -Status "Complete" -Completed