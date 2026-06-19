# Calc

A native SwiftUI calculator. Builds to an **unsigned** `.ipa` in the cloud — no Mac needed.
Feather signs it with your cert at install time.

## Get an .ipa with GitHub Actions (free, recommended)

1. Make a new repo on GitHub (public = free macOS minutes).
2. Put all these files in it, keeping the structure:

   ```
   project.yml
   Sources/CalcApp.swift
   Sources/ContentView.swift
   .github/workflows/build.yml
   ```

3. Push to the `main` branch. The build runs automatically.
   (Or open the **Actions** tab and hit **Run workflow**.)
4. When it finishes, open the run → **Artifacts** → download **Calc-ipa**.
   It downloads as a `.zip`; inside is `Calc.ipa`.
5. Open `Calc.ipa` in **Feather** → it signs with your cert → installed.

## Alternative: Codemagic (point-and-click, no YAML)

1. Sign in at codemagic.io and connect the repo.
2. Project type: iOS App. Build for **Release**, **without code signing**.
3. Download the `.ipa` artifact when it's done, open in Feather.

## Editing it later

All the logic is in `Sources/ContentView.swift` (the `Calculator` struct).
Change it, push, and a fresh `.ipa` pops out. That's the loop.
