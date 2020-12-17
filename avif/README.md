# Convert images to WEBP

## Requirements:
* cavif tool for 2WEBP (https://github.com/kornelski/cavif-rs)
* Go-avif tool for 2WEBP_QP (https://github.com/Kagami/go-avif)

## Usage
* download selected *.cmd script
* download the tool
* place the script and the tool into same folder (or place the tool inside `bin` sub-folder)
* Drag and drop selected JPG or PNG images onto the script (or its LNK Shortcut).
* Write a number of quality you want to use. You can press Enter to use the default quality.
* Wait until all images are processed.


## Description of `2AVIF`

This script converts images into AVIF with selected quality.

This script supports transparency and JPG-like quality settings.
This script does not support LOSSLESS compression.

This script may create images incompatible with Windows Explorer and MS paint.
You need Paint.net or other tools to see or edit produced images.

## Description of `2AVIF_QP`

This script converts images into AVIF based on Quantification Parameter (which is a value known from AVC and HEVC CRF encoders).

This script does NOT support transparency and can be used only for converting JPGs and non-transparent PNGs.
This script does not support LOSSLESS compression.


## _View AVIF on Windows_

_Please install the "AV1 Video Extension" from Microsoft store to add support for
AVIF images. This extension will allow you to see thumbnails in Windows Explorer
and you will be able to open the images in MS Paint._

## For developers
When you fork this repository, you can place the tool directly into you Working Copy. The GIT is configured to ignore EXE and LOG files.

You can change the process_app variable if you want to use another tool with the script.

You can change the QUALITY variable to set default quality. 
