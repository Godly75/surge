# Vital Preset Generator Script

## Overview

`create-vital-presets.ps1` is a PowerShell script that automates the creation of Vital synthesizer presets from WAV files. It takes a template `.vital` preset file and generates individual presets for each WAV file found in a specified directory.

## Features

- Batch processing of multiple WAV files
- Uses a template preset as the base configuration
- Assigns WAV files to specified oscillator (1, 2, or 3)
- Generates properly formatted Vital preset files (.vital)
- Preserves original template settings while updating sample paths
- Color-coded console output for easy monitoring
- Comprehensive error handling and validation

## Requirements

- PowerShell 5.0 or higher
- Windows operating system
- A valid `.vital` template file
- Directory containing WAV files

## Usage

### Basic Syntax

```powershell
.\create-vital-presets.ps1 -InitVital <template-path> -WavFolder <wav-directory> -OutputFolder <output-directory>
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-InitVital` | Yes | Path to the init.vital template file |
| `-WavFolder` | Yes | Path to folder containing WAV files |
| `-OutputFolder` | Yes | Path to output folder for generated presets |
| `-Oscillator` | No | Oscillator index (1-3) to assign samples to. Default: 1 |
| `-Help` | No | Display help information |

### Examples

**Basic usage:**
```powershell
.\create-vital-presets.ps1 -InitVital "C:\Templates\init.vital" -WavFolder "C:\Samples" -OutputFolder "C:\Presets"
```

**Using relative paths:**
```powershell
.\create-vital-presets.ps1 -InitVital ".\templates\init.vital" -WavFolder ".\samples" -OutputFolder ".\output"
```

**Assigning to oscillator 2:**
```powershell
.\create-vital-presets.ps1 -InitVital ".\init.vital" -WavFolder ".\wavs" -OutputFolder ".\presets" -Oscillator 2
```

**Display help:**
```powershell
.\create-vital-presets.ps1 -Help
```

## How It Works

1. **Validation**: The script validates that the init.vital file exists and is valid JSON
2. **Scanning**: Scans the specified folder for all `.wav` files
3. **Processing**: For each WAV file:
   - Loads the template preset
   - Updates the sample path for the specified oscillator
   - Enables the oscillator
   - Sets the preset name based on the WAV filename
   - Saves the modified preset with a `.vital` extension
4. **Summary**: Displays a summary of successful and failed operations

## File Structure

The generated presets will:
- Be named after the WAV files (without extension)
- Include the full path to the WAV file in the preset
- Retain all other settings from the template
- Be saved in JSON format compatible with Vital

## Tips

- **Template Creation**: Create your ideal base preset in Vital and save it as your template file
- **WAV Organization**: Organize your WAV files by category in separate folders for easier batch processing
- **Multiple Oscillators**: Run the script multiple times with different oscillator numbers to assign samples to different oscillators
- **Backup**: Keep a backup of your template file before experimenting

## Troubleshooting

**"Init.vital file not found"**
- Verify the path to your template file is correct
- Use absolute paths if relative paths aren't working

**"No WAV files found"**
- Ensure the folder path is correct
- Verify files have the `.wav` extension (case-sensitive on some systems)

**"Invalid Vital preset file"**
- The template file must be valid JSON
- Open the file in Vital and re-save it if necessary

**Permission errors**
- Run PowerShell as Administrator if you encounter permission issues
- Ensure the output folder is writable

## Execution Policy

If this is your first time running PowerShell scripts, you may need to set the execution policy:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Related Scripts

This script is similar in concept to the Python wavetable tools in `scripts/wt-tool/`:
- `wt-tool.py` - Creates Surge wavetables from WAV files
- Both scripts batch process audio files to create synthesizer assets

## License

This script is part of the Surge project and is licensed under GPL-3.0.

## Support

For issues or questions:
- Check the Surge project documentation
- Visit the Surge Synth Team forum
- Submit an issue on GitHub
