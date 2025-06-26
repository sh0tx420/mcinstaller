# mcinstaller - Minecraft server installer
Minecraft server installer written entirely in Bash.

### Usage
```
Usage: ./install.sh [options]

Options:
  -h, --help        Display this help message
  -m, --mcver       Specify Minecraft version to install to server
                    (latest or x.xx.x format)
  -s, --software    Specify server software to use with Minecraft server
                    (vanilla, paper, purpur)
  -p, --preset      Select presets to install with extra features
                    (vanillasmpplus)
  -o, --output      Directory, where to install server (defaults to ./server/)

```

### Installation & running
- **Method 1:** Download the Git repository and run `install.sh` with your favorite options, OR:
- **Method 2:** Run the following command to automatically install a Paper server to your current working directory:
```
wget -O - https://raw.githubusercontent.com/sh0tx420/mcinstaller/main/download.sh | bash
```

### Features
- **Installer presets** - Apply configurations after server installation to get server up and running in just a few seconds
- **PaperMC support** - Install a server with PaperMC out of the box
- **Full installation** - The script automatically downloads and generates the required files to get your server ready to run immediately
