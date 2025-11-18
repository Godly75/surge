# create-vital-presets.ps1
# 
# A PowerShell script to create Vital synthesizer presets from WAV files
# This script takes an init.vital template file and generates separate
# Vital presets for each WAV file found in a specified directory.
#
# Usage:
#   .\create-vital-presets.ps1 -InitVital "path\to\init.vital" -WavFolder "path\to\wavs" -OutputFolder "path\to\output"
#
# Requirements:
#   - PowerShell 5.0 or higher
#   - An init.vital template file
#   - Directory containing WAV files

Param(
    [Parameter(Mandatory=$false, HelpMessage="Path to the init.vital template file")]
    [string]$InitVital,
    
    [Parameter(Mandatory=$false, HelpMessage="Path to folder containing WAV files")]
    [string]$WavFolder,
    
    [Parameter(Mandatory=$false, HelpMessage="Path to output folder for generated presets")]
    [string]$OutputFolder,
    
    [Parameter(Mandatory=$false, HelpMessage="Oscillator index to assign sample to (1, 2, or 3)")]
    [ValidateRange(1,3)]
    [int]$Oscillator = 1,
    
    [switch]$Help
)

function Show-Help {
    Write-Host @"
create-vital-presets.ps1 - Generate Vital presets from WAV files

DESCRIPTION:
    This script reads an init.vital template file and creates separate Vital 
    synthesizer presets for each WAV file found in the specified folder. Each 
    generated preset will have the WAV file assigned as a sample source.

PARAMETERS:
    -InitVital <path>
        Path to the init.vital template file. This file serves as the base
        preset configuration.
        
    -WavFolder <path>
        Path to the folder containing WAV files. All .wav files in this
        folder will be processed.
        
    -OutputFolder <path>
        Path to the output folder where generated .vital presets will be saved.
        The folder will be created if it doesn't exist.
        
    -Oscillator <1|2|3>
        Oscillator index to assign the sample to. Valid values are 1, 2, or 3.
        Default is 1 (oscillator 1).
        
    -Help
        Display this help message.

EXAMPLES:
    .\create-vital-presets.ps1 -InitVital "C:\Templates\init.vital" -WavFolder "C:\Samples" -OutputFolder "C:\Output"
    
    .\create-vital-presets.ps1 -InitVital ".\init.vital" -WavFolder ".\wavs" -OutputFolder ".\presets" -Oscillator 2

NOTES:
    - The init.vital file must be a valid Vital preset in JSON format
    - WAV files should be compatible with Vital (mono or stereo, various sample rates supported)
    - Generated preset names will be based on the WAV file names
    - Existing files in the output folder with the same name will be overwritten

"@
}

function Test-VitalFile {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    try {
        $content = Get-Content $Path -Raw
        $json = $content | ConvertFrom-Json
        return $true
    }
    catch {
        return $false
    }
}

function Get-WavFiles {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "WAV folder does not exist: $Path"
    }
    
    $wavFiles = Get-ChildItem -Path $Path -Filter "*.wav" -File
    return $wavFiles
}

function New-VitalPreset {
    param(
        [string]$TemplateContent,
        [string]$SamplePath,
        [string]$PresetName,
        [int]$OscillatorIndex
    )
    
    try {
        # Parse the template JSON
        $preset = $TemplateContent | ConvertFrom-Json
        
        # Determine the oscillator key name (osc_1, osc_2, or osc_3)
        $oscKey = "osc_$OscillatorIndex"
        
        # Update the sample path for the specified oscillator
        if ($preset.settings.PSObject.Properties.Name -contains $oscKey) {
            # Set the sample source
            $sampleKey = "sample"
            if ($preset.settings.$oscKey.PSObject.Properties.Name -contains $sampleKey) {
                $preset.settings.$oscKey.sample = $SamplePath
            }
            else {
                # Add sample property if it doesn't exist
                $preset.settings.$oscKey | Add-Member -NotePropertyName "sample" -NotePropertyValue $SamplePath -Force
            }
            
            # Enable the oscillator
            $onKey = "${oscKey}_on"
            if ($preset.settings.PSObject.Properties.Name -contains $onKey) {
                $preset.settings.$onKey = 1
            }
            else {
                $preset.settings | Add-Member -NotePropertyName $onKey -NotePropertyValue 1 -Force
            }
            
            # Set oscillator to sample mode (typically value 5 or 6 for sample playback)
            $waveKey = "${oscKey}_wave_frame"
            if ($preset.settings.PSObject.Properties.Name -contains $waveKey) {
                # Keep existing wave_frame value or set to sample mode
            }
        }
        else {
            Write-Warning "Oscillator $OscillatorIndex not found in template. Adding basic configuration."
            # Add a basic oscillator configuration
            $preset.settings | Add-Member -NotePropertyName $oscKey -NotePropertyValue @{
                "sample" = $SamplePath
            } -Force
            $preset.settings | Add-Member -NotePropertyName "${oscKey}_on" -NotePropertyValue 1 -Force
        }
        
        # Update preset name if the property exists
        if ($preset.PSObject.Properties.Name -contains "preset_name") {
            $preset.preset_name = $PresetName
        }
        elseif ($preset.PSObject.Properties.Name -contains "name") {
            $preset.name = $PresetName
        }
        else {
            $preset | Add-Member -NotePropertyName "preset_name" -NotePropertyValue $PresetName -Force
        }
        
        # Update author and comments if desired
        if ($preset.PSObject.Properties.Name -contains "author") {
            $preset.author = "$($preset.author) + Surge Script"
        }
        
        # Convert back to JSON with proper formatting
        $outputJson = $preset | ConvertTo-Json -Depth 100
        
        return $outputJson
    }
    catch {
        throw "Error creating preset: $_"
    }
}

function Main {
    # Show help if requested or if required parameters are missing
    if ($Help -or [string]::IsNullOrEmpty($InitVital) -or [string]::IsNullOrEmpty($WavFolder) -or [string]::IsNullOrEmpty($OutputFolder)) {
        Show-Help
        if (-not $Help) {
            Write-Host ""
            Write-Error "Missing required parameters. Please provide -InitVital, -WavFolder, and -OutputFolder"
        }
        return
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Vital Preset Generator from WAV Files" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Validate init.vital file
    Write-Host "Validating init.vital file..." -ForegroundColor Yellow
    if (-not (Test-Path $InitVital)) {
        Write-Error "Init.vital file not found: $InitVital"
        return
    }
    
    if (-not (Test-VitalFile $InitVital)) {
        Write-Error "Invalid Vital preset file: $InitVital"
        return
    }
    
    Write-Host "✓ Init.vital file is valid" -ForegroundColor Green
    
    # Load template content
    $templateContent = Get-Content $InitVital -Raw
    
    # Get WAV files
    Write-Host "Scanning for WAV files..." -ForegroundColor Yellow
    try {
        $wavFiles = Get-WavFiles -Path $WavFolder
    }
    catch {
        Write-Error $_
        return
    }
    
    if ($wavFiles.Count -eq 0) {
        Write-Warning "No WAV files found in: $WavFolder"
        return
    }
    
    Write-Host "✓ Found $($wavFiles.Count) WAV file(s)" -ForegroundColor Green
    Write-Host ""
    
    # Create output folder if it doesn't exist
    if (-not (Test-Path $OutputFolder)) {
        Write-Host "Creating output folder: $OutputFolder" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    }
    
    # Process each WAV file
    $successCount = 0
    $errorCount = 0
    
    foreach ($wavFile in $wavFiles) {
        $presetName = [System.IO.Path]::GetFileNameWithoutExtension($wavFile.Name)
        $outputFile = Join-Path $OutputFolder "$presetName.vital"
        
        Write-Host "Processing: $($wavFile.Name)" -ForegroundColor Cyan
        Write-Host "  → Creating preset: $presetName.vital" -ForegroundColor Gray
        
        try {
            # Create the preset with the WAV file path
            $presetJson = New-VitalPreset -TemplateContent $templateContent `
                                          -SamplePath $wavFile.FullName `
                                          -PresetName $presetName `
                                          -OscillatorIndex $Oscillator
            
            # Save the preset
            $presetJson | Out-File -FilePath $outputFile -Encoding UTF8 -Force
            
            Write-Host "  ✓ Saved: $outputFile" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Error "  ✗ Failed to create preset: $_"
            $errorCount++
        }
        
        Write-Host ""
    }
    
    # Summary
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Total WAV files: $($wavFiles.Count)" -ForegroundColor White
    Write-Host "  Successful: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "White" })
    Write-Host "  Output folder: $OutputFolder" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
}

# Run the main function
Main
