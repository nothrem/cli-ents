# Optimize PNG images

## Requirements (at least one of the tools should be used):
* PNGoptimizer (https://psydk.org/pngoptimizer)
* APNGASM (http://apngasm.sourceforge.net/)
* APNG Optimizer (https://sourceforge.net/projects/apng/files/APNG_Optimizer/)
* OptiPNG (http://optipng.sourceforge.net/)
* ZopfliPNG (https://github.com/imagemin/zopflipng-bin/blob/master/vendor/win32/zopflipng.exe)

## Usage
* download selected *.cmd script
* download the tool(s) of your preferrence
* place the script and the tool into same folder ~~(or place the tool inside `bin` sub-folder)~~
* Drag and drop selected PNG images onto the script (or its LNK Shortcut).
* Wait until all images are processed.


## Description of tools

### PNG optimizer

This is simple tool that removes extra data from the PNG image (EXIF data etc.). This tool does not compress the image,
but especially for small images (icons) the extra data may take more than 50% of the file and are not need to display the image.

### APNGASM

This tool is used to create animated PNG images. APNG is newer version of PNG and is backward compatible with all tools.
In some cases recreating the PNG as single-frame APNG may save some bytes.

If this tool is used, the script will create two files (normal and animated), optimize them both and then select the better one.

### APNG Optimizer

This tool is based on APNG format and uses some of its features to optimize the PNG and save few more bytes. One of the features
is using 7ZIP instead of zlib/deflate compression.

### OptiPNG

This is another PNG optimizer that uses series of optimization processes to remove redundant data (e.g. unused colors in the palette).
You can find more about all the optimizations at http://optipng.sourceforge.net/pngtech/optipng.html .

### ZopfliPNG

Zopfli is a new (2013) ZIP-like compression algorithm developed by Google.
The zopfli compression is about 5% - 10% than 7Zip, but the compression
takes very long (minutes or even hours for 1+MPix pictures). 

Zopfli produces a DEFLATE stream which is compatible with all Zlib or 7zip libraries,
so it does not need any special tool for decompression.

ZopfliPNG is a tool that uses the Zopfli compression on a PNG file and produces 
file that is ~10% smaller than any other optimization tool can produce.

**To change the speed of zopfli compression, you can change the parameter `--iterations`**
of the command. Less iterations will process the file faster but may miss some
compression opportunities and in specific cases may produce larger file.
More (up to 100) iterations will process the file for much longer time
but for specific files may achieve better compression and smaller file.
However, a positive effect of using more than 15 iteration is very rare and in most
cases will just waste time without any additional compression, so it's not really
meaningful to use it unless you don't case about how long the compression takes.

## Usage with RIOT

RIOT (https://riot-optimizer.com/) is great optimization tool which can also
use external programs and scripts for further optimization.

RIOT does not support CMD files, so you will have to rename the script to *.BAT.
This will also automatically disable the "pause" on the end.

Run RIOT and switch to PNG (on the bottom). Click [+] inside External optimizers frame and fill values:
  
    Tool name: BestPNG
    Tool path: C:\Cli-ents.git\png\bestPNG.bat
    Parameters: {IMAGE_FILE}

Click OK and click the Green check mark. Now, when you open or Drag&Drop an image, it will be automatically
converted to PNG and optimized by the bestPNG script.

## For developers
When you fork this repository, you can place the tool directly into you Working Copy. The GIT is configured to ignore EXE and LOG files.
