# Define the path to the images
#$imagesPath = "C:\Users\zeand\Downloads\OneDrive Pictures\downscaled"
$imagesPath = "C:\Users\zeand\Downloads\Google Photos\Photos\Downscaled"
$duplicatesPath = "$imagesPath\duplicates\"
if (-not (Test-Path -Path $duplicatesPath)) {
    New-Item -ItemType Directory -Path $duplicatesPath
}

# Get all image files in the directory
$imageFiles = Get-ChildItem -Path $imagesPath -Filter *.jpg
$totalFiles = $imageFiles.Count

# Function to compare images using Python script
function Compare-Images {
    param (
        [string]$image1,
        [string]$image2
    )
    $result = python.exe hash_images.py $image1 $image2
    return [int]$result
}

# Loop through the images and find duplicates
for ($i = 0; $i -lt $imageFiles.Count; $i++) {
    $imageFile = $imageFiles[$i]
    if (Test-Path $imageFile.FullName) {
        $duplicateCount = 0
        $difference = 0

        # Update progress
        $percentComplete = [math]::Round(($i / $totalFiles) * 100)
        Write-Progress -Activity "Finding duplicates ($duplicateCount)" -Status "Processing $($imageFile.Name)" -PercentComplete $percentComplete

        for ($j = 1; ($difference -lt 10) -and ($j -le 8) -and ($i + $j) -lt $imageFiles.Count; $j++) {
            $nextImageFile = $imageFiles[$i + $j]
            $difference = Compare-Images -image1 $imageFile.FullName -image2 $nextImageFile.FullName

            if ($difference -lt 10) { # Adjust the threshold as needed
                Move-Item -Path $nextImageFile.FullName -Destination $duplicatesPath
                $duplicateCount++
            }
        }

        if ($duplicateCount -gt 0) {
            Copy-Item -Path $imageFile.FullName -Destination $duplicatesPath
        }
    }
}

# Clear the progress bar
Write-Progress -Activity "Finding duplicates" -Status "Complete" -Completed