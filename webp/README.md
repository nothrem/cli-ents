# Convert images to WEBP

## Requirements:
* cwebp tool (https://developers.google.com/speed/webp/download)

## Usage
* download selected *.cmd script
* download the tool
* place the script and the tool into same folder (or place the tool inside `bin` sub-folder)
* Drag and drop selected JPG or PNG images onto the script (or its LNK Shortcut).
* Write a number of quality you want to use. You can press Enter to use the default quality.
* Wait until all images are processed.

## Description of `2WEBP_auto`

This script converts images into WEBP with selected quality.

After the conversation the script checks the size of the WEBP file and if the file
is larger or similar size as the original, it deletes the file and tries again
with quality lowered by 10 points.

The script continues until it finds quality that produce file smaller by either
more than 1 kB or more than 10% of the original size.

## For developers
When you fork this repository, you can place the tool directly into you Working Copy. The GIT is configured to ignore EXE and LOG files.

You can change the process_app variable if you want to use another tool with the script.

You can change the QUALITY variable to set default quality. 
