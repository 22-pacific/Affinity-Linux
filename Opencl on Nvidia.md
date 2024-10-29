# Opencl on Nvidia
If you have Nvidia GPU, you can enable opencl (hardware accelaration) by following below steps

## Installing OpenCL Drivers for Nvidia GPU

Ensure the GPU drivers and OpenCL drivers are installed for your GPU.

For example, on **Arch Linux** & **Nvidia**:
```
sudo pacman -S opencl-nvidia
```

## Installing VKD3D-Proton

Download [VKD3D-Proton](https://github.com/HansKristian-Work/vkd3d-proton) for Lutris from [ProtonPlus](https://github.com/Vysp3r/ProtonPlus) or [Protonupqt](https://github.com/DavidoTek/ProtonUp-Qt)

## Add Affinity apps to lutris

*in configuration, set the wine-version to custom and add the custom wine executable to

```
/opt/wines/affinity-photo3-wine9.13-part3/bin/wine
```

## Configuring Lutris

1. Open Lutris and go to the affinity app's configuration settings.
2. Navigate to **Runner Options**.
3. Select **vkd3d-proton** as the VKD3D version.
4. Disable **DXVK**.

## Launching Affinity Apps

Run the Affinity apps and verify OpenCL is working by checking the preferences for hardware acceleration.
