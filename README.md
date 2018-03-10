# cnlabSpeedTestLinux

Scripts for downloading / installing and running the popular Connection-Speedtest under Linux.

***Please note that I am not affiliated with the cnlab in any way. The SpeedTest Performance Software is their copyrighted Product and may not be redistributed freely. The Scripts provided here are simple wrappers that make the Software installable and executable on Linux Platforms.***

## Quick Introduction

The popular Internet Connection Test written in Java by cnlab ([http://www.cnlab.ch](http://www.cnlab.ch)) is officially released in Versions for Windows and Mac, however the Utility runs perfectly well under Linux, too.

To take the pain out of scraping up all the bits needed to run the SpeedTest on Linux, I wrote these two Scripts.

## Installing

In order to install the SpeedTest program the easiest way is to download the `cnlabSpeedTestLinux-Setup.sh` Script ***only*** (the second Script, the launcher (`cnlabSpeedTest-Linux.sh`) is automatically downloaded by the Setup-Script during installation.

Run the Setup-Script by opening a Terminal Application (on most Linux Distributions this can easily be achieved by pressing `Ctrl` + `Alt` + `T` ).
Next cd into the Directory, where the Script has been downloaded to, e.g. `~/Downloads` and make the script executable by typing

`chmod u+x cnlabSpeedTestLinux-Setup.sh`


Launch the installation routine by typing

`sh cnlabSpeedTestLinux-Setup.sh`

After the script has terminated successfully, you can safely delete the Setup-Script from your Computer, it is no longer needed.

## Questions? Diffuculties? Errors?

Please have a look at the FAQs in the [Wiki](https://github.com/tobiasvogel/cnlabSpeedTestLinux/wiki).
