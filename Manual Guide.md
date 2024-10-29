## Dependencies
## Required dependencies

## Debian

```
sudo apt install git winetricks
```
## Arch Linux

```
sudo pacman pacman -S git winetricks
```

## Fedora
```
sudo dnf install git winetricks
```
## Opensuse
```
sudo zypper install git winetricks
```

## Installing Lutris
## Fedora

```
sudo dnf in lutris
```
## Arch Linux

```
sudo pacman -S lutris
```
## Debian

```
sudo apt install lutris
```

## Installing Affinity Linux's Prebuilt Wine
Download the newest release [Here](https://github.com/22Pacific/ElementalWarrior-wine-binaries/releases/tag/affinity-photo3-wine9.13-part3)

Extract the Elemental Warrior's Pre-built wine binaries to Lutris wine directory

## Lutris
```
$HOME/.local/share/lutris/runners/wine/
```


## Downloading Affinity

[Affinity Designer](https://store.serif.com/update/windows/designer/2/)

[Affinity Photo](https://store.serif.com/update/windows/photo/2/)

[Affinity Publisher](https://store.serif.com/update/windows/publisher/2/)

From the Drop down Choose the exe

## Settings Up Lutris For Affinity
Open up lutris and then click on

* add button(+)

and at the bottom

* Add Locally Install Game

Name it According to the Affinity app you are using

## Setting the Wine Version

Set the wine version to ElementalWarriorWine

## Selecting the Programs .exe According to what you Want to Install

Select the setup .exe you've downloaded from affinity's website as the executable

Click Finish

## Initialize the prefix

In order to initialize the prefix run the setup file from lutris. (It'll probably crash wait for it to crash if it somehow opens up close it yourself)

## Setting Up Affinity Wine Settings and Winetricks

* click on an affinity app on lutris and navigate to wine section on the bottom

* open winetricks from there (it will open up a popup window which is winetrick GUI)

* Select the default wineprefix
* install a windows dll and components

and click OK

 Search & install these dependencies;

* dotnet48
* vcrun2015

click ok

* install a font

click ok

* Search & install
* corefonts

(Wait while its installing the dependencies. Its %90 not stuck but rather taking its time!!!)

* click ok

* Change settings

Toggle
 * win11

Toggle
 * renderer=vulkan

and click OK

Keep pressing "Cancel" till the winetricks window closes

## Placing WinMetadata

Unzip [WinMetadata.zip](https://archive.org/download/win-metadata/WinMetadata.zip)

to  drive_c/windows/system32 on the wineprefix

## Running Affinity Setup and Installing Photo/Designer/Publisher

Press launch and the setup should work

Once its done installing right click to affinity on lutris and go to configure
* Game options

Next Change the executable to

* drive_c/Program Files/Affinity/Photo 2/Photo.exe
* drive_c/Program Files/Affinity/Designer 2/Designer.exe
* drive_c/Program Files/Affinity/Publisher 2/Publisher.exe

Click save & launch it.

## Opencl on Nvidia
If you have Nvidia GPU, you can enable opencl (hardware accelaration) by following below steps

## Installing OpenCL Drivers for Nvidia GPU

Ensure the GPU drivers and OpenCL drivers are installed for your GPU.

For example, on **Arch Linux** & **Nvidia**:
```
sudo pacman -S opencl-nvidia
```

## Installing VKD3D-Proton

Download [VKD3D-Proton](https://github.com/HansKristian-Work/vkd3d-proton) for Lutris from [ProtonPlus](https://github.com/Vysp3r/ProtonPlus) or [Protonupqt](https://github.com/DavidoTek/ProtonUp-Qt)

## Configuring Lutris

1. Open Lutris and go to the affinity app's configuration settings.
2. Navigate to **Runner Options**.
3. Select **vkd3d-proton** as the VKD3D version.
4. Disable **DXVK**.

## Launching Affinity Apps

Run the Affinity apps and verify OpenCL is working by checking the preferences for hardware acceleration.
