## Setting up elementalwarrior's wine fork with the script
```
curl -sSL https://raw.githubusercontent.com/22-pacific/Affinity-Linux/main/elementalwarriror-wine-setup.sh | bash
```
(the script will take some time please wait until its done)

*After the script is done, you can install Affinity apps by using lutris

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

in configuration, set the wineprefix to
 * $HOME/.AffinityLinux

 in configuration, set the wine-version to custom and add the custom wine executable to
 * $HOME/.AffinityLinux/ElementalWarriorWine/bin/wine

## Selecting the Programs .exe According to what you Want to Install

 Select the setup .exe you've downloaded from affinity's website as the executable

 Click Finish


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
