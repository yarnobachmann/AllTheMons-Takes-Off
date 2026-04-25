# All The Mons Takes Off

Self-hosted packwiz modpack for installing **All The Mons Takes Off** in Prism Launcher.

## Prism install link

After GitHub Pages is enabled for this repository, paste this into Prism Launcher's **Add Instance > Import > Link** field:

```text
https://yarnobachmann.github.io/AllTheMons-Takes-Off/All-The-Mons-Takes-Off-1.0.0-prism.zip
```

The pack entry point is:

```text
https://yarnobachmann.github.io/AllTheMons-Takes-Off/pack.toml
```

## Pack details

- Minecraft: `1.21.1`
- Loader: `NeoForge`
- NeoForge: `21.1.227`
- Recommended memory: `8192 MB`

## Publish steps

```powershell
git init
git branch -M main
git remote add origin https://github.com/yarnobachmann/AllTheMons-Takes-Off.git
git add .
git commit -m "Create Prism installable modpack"
git push -u origin main
```

Then enable GitHub Pages:

1. Open the repository on GitHub.
2. Go to **Settings > Pages**.
3. Set source to **Deploy from a branch**.
4. Select branch `main` and folder `/root`.
5. Save.

## Updating later

Run these after changing mods, config, resource packs, shader packs, data packs, or root files:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\generate-modrinth-metafiles.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\build-prism-zip.ps1
```

Commit and push the changed files when the scripts finish.
