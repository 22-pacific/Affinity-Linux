## Setting up affinity v3 with script
```
curl -L https://raw.githubusercontent.com/22-pacific/Affinity-Linux/main/affinity-setup.sh | bash
```

## Setting up only elementalwarrior's wine fork with the script
```
curl -L https://raw.githubusercontent.com/22-pacific/Affinity-Linux/main/elementalwarriror-wine-setup.sh | bash
```
(the script will take some time please wait until its done)

*After the script is done, you can install Affinity apps by using lutris

## Setting up affinity plugin loader for fixing settings saving and wine fixes
```
curl -L https://raw.githubusercontent.com/22-pacific/Affinity-Linux/main/affinity-plugin-loader.sh | bash
```
AffinityPluginLoader (Recommended Method)

### Install Affinity Plugin Loader + WineFix  
> **Author:** [Noah C3](https://github.com/noahc3)  
> **Project:** [AffinityPluginLoader + WineFix](https://github.com/noahc3/AffinityPluginLoader/)  
> *This patch is community‑made and **not official**, but it greatly improves runtime stability and fixes the “Preferences not saving” issue on Linux.*

### Purpose
- Provides plugin loading and dynamic patch injection via **Harmony**  
- Restores **on‑the‑fly settings saving** under Wine  
- Temporarily skips the Canva sign‑in dialog (until the browser redirect fix is ready)

---

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

## Settings Up Lutris For Affinity
Open up lutris and then click on

* add button(+)

and at the bottom

* Add Locally Install Game

Name it 

in configuration, set the wineprefix to
 * $HOME/.wineAffinity

 in configuration, set the wine-version to custom and add the custom wine executable to
 * /opt/wines/affinity-photo3-wine9.13-part3/bin/wine

 Click save & launch it.

## Opencl on Nvidia
If you have Nvidia GPU, you can enable opencl (hardware accelaration) by following below steps

## Installing OpenCL Drivers for Nvidia GPU

Ensure the GPU drivers and OpenCL drivers are installed for your GPU.

For example, on **Arch Linux** & **Nvidia**:
```
sudo pacman -S opencl-nvidia
```

## Configuring Lutris

1. Open Lutris and go to the affinity app's configuration settings.
2. Navigate to **Runner Options**.
3. Select **The latest VKD3D** as the VKD3D version.
4. Disable **DXVK**.

Run the Affinity apps and verify OpenCL is working by checking the preferences for hardware acceleration.
