# server-diary
generates very detailed e-mails with graphs and statistics on what was happening on you server during the last days

### WARNING: This is a prototype. Don't run it on your server yet!

## Installation

This script is written in julia language. You need to install julia 1.3 or newer, for example using

```
sudo add-apt-repository ppa:jonathonf/julialang
sudo apt-get update
sudo apt install julia
```

Optionally, you can also install pngquant to compress the pngs and send smaller emails: `sudo apt install pngquant`

To install and build the dependencies of julia, run `julia install.jl`. If you want to run this package as cronjob, make sure to run the `install.jl` from the same user as the cron job.

Currently, the only supported backend is `sysstat`. So make sure `sysstat`, `sar` and `sadf` are installed and properly configured.

## Usage

Run `julia server-diary.jl`. It will generate a file `stats.email` which is a multipart-html-email with images. You can send it using `sendmail -i -t < stats.email`.

Old graphs are archived in the `stats` folder. Feel free to delete them if they become too many.

