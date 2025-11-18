# Affinity-Linux

## Introduction
Installation and Usage Guide for Serif's [Affinity](https://affinity.serif.com/en-us/) Graphics Suite on Linux using [ElementalWarrior](https://gitlab.winehq.org/ElementalWarrior)'s Wine fork. This guide is based on [Affinity Wine Documentation by Wanesty](https://affinity.liz.pet/).

The guide is an easy to follow step-by-step process on GUI without requiring to compile [ElementalWarrior](https://gitlab.winehq.org/ElementalWarrior)'s Wine and without rum.

The Wine setup script is for setting up wine, wineprefix and rum without needing to compile [ElementalWarrior](https://gitlab.winehq.org/ElementalWarrior)'s Wine.

This guide helps Installing and running Affinity apps on linux as very usable state with opencl (hardware accelaration) enabled for Nvidia users (needs Vkd3d-proton) on Affinity apps.

(Note: Affinity software version 1.10.4 and later releases require .winmd files from an existing Windows 10+ install.)

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

## [Wine setup Script and Installation](https://github.com/22-pacific/Affinity-Linux/blob/main/script%20wine%20setup.md)

## [Manual Guide Installation](https://github.com/22-pacific/Affinity-Linux/blob/main/Manual%20Guide.md)

____________________________________________________________________________________________
*if you already have installed affinity apps by following Wanesty's guide, you can refere to

## [Opencl on Nvidia](https://github.com/22-pacific/Affinity-Linux/blob/main/Opencl%20on%20Nvidia.md)
