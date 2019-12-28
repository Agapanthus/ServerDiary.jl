# ServerDiary
Generates very detailed e-mails with graphs and statistics on what was happening on you server during the last days

### WARNING: This is a prototype. Don't run it on your server yet!

## Installation

This script is written in julia language. You need to install julia 1.3 or newer, for example using

```
sudo add-apt-repository ppa:jonathonf/julialang
sudo apt-get update
sudo apt install julia
```
You also need to install pngquant to compress the pngs and send smaller emails: `sudo apt install pngquant`

To install this package and its julia dependencies enter your Julia CLI and type `]` to enter the Pkg-manager. Now enter `add https://github.com/Agapanthus/ServerDiary.jl`.

If you prefer to download manually, cd the package and run `julia install.jl`. If you are going to run this as a cronjob, make sure to install it for the same user as the cronjob is running!

Currently, the only supported backend is `sysstat`. So make sure `sysstat` and `sar` are installed and properly configured.

## Usage

Run `julia ServerDiary/run.jl`. It will generate a file `stats.email` which is a multipart-html-email with images. You can send it using `sendmail -i -t < stats.email`.
The script might take a minute to start because it imports the Plots.jl package.

Old graphs are archived in the `stats` folder. Feel free to delete them if they become too many.

