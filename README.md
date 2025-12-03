# mh2p-lsd-mods

## Overview

This repository hosts source code and tooling for creating mods to the MH2P LSD (Life Simulation Device) system. It provides a workflow for decompiling the original `lsd.jar` from the PCM system, patching the Java source, building mod jars compatible with the original game environment, and packaging them for ModKit installation.

---

## Requirements

- Java 8 JDK (for Gradle and compilation tooling)
- [CFR decompiler](https://www.benf.org/other/cfr/) (tested with cfr-0.152.jar)
- Unix-like shell environment (Linux, macOS, or WSL)
- Git
- Gradle (wrapper included)

---

## Repository Layout

```
.
├── original/
│   └── lsd.jar               # [compile-time dependency] Place your original jar copied from your PCM's /mnt/app/eso/hmi/lsd/lsd.jar directory
├── lsd-src/                  # Decompiled full Java source of lsd.jar - see 'Creating / Updating `lsd-src`' section
├── patch-project/            # Gradle project that builds mod jars
│   └── src/main/java/        # Source files copied from lsd-src for patching. Created when running prepare.sh / build.sh
├── modkit/                   # Generated ModKit-ready mod folders per branch
│   └── templates/            # Modkit Templates for install/uninstall scripts and README
│   └── *branch\modkit-name*/ # Generated mod repository/folders per patch branch (e.g. modkit/menu-facelift/)
├── scripts/                  # Shell scripts for dev workflow and modkit packaging
│   ├── dev/                  # Dev scripts for prepare, build, validate, deploy, etc.
│   │   ├── all.sh            # Convenience: prepare -> build -> validate -> deloy -> restart
│   │   ├── build.sh          # Build patch jar via Gradle
│   │   ├── deploy.sh         # Deploy built jar to PCM file system via SSH/SCP
│   │   ├── prepare.sh        # Sync selected sources into patch-project
│   │   ├── restart.sh        # Helper to reboot PCM
│   │   └── validate.sh       # Validate built jar contents and diffs
│   ├── dev.env               # Environment variables for dev scripts (host, SSH key, etc.)
│   └── modkit/
│       └── build.sh          # Build ModKit-ready folder for the current patch branch
├── patch-config.sh           # Per-branch patch config (defines jar basename, base branch)
├── patch-files.txt           # Per-branch list of source files included in the patch
└── patch-files.example.txt   # Example of patch-files.txt format
```

---

## Creating / Updating `lsd-src`

To generate or refresh the decompiled source in `lsd-src/`:

1. Copy the original `lsd.jar` from the PCM system into `original/`:

   ```bash
   cp /path/to/pcm/lsd.jar original/
   ```

2. If CFR fails with errors like `Invalid CEN header` or `ConfusedCFRException`, fix the jar by unzipping and re-jarring:

   ```bash
   cd original
   unzip lsd.jar -d lsd-unpacked
   jar cf lsd-fixed.jar -C lsd-unpacked .
   cd ..
   ```

3. Decompile the fixed jar using CFR into `lsd-src/`:

   ```bash
   java -jar cfr-0.152.jar original/lsd-fixed.jar --outputdir lsd-src
   ```

   If no errors occur, you can decompile directly from `lsd.jar`:

   ```bash
   java -jar cfr-0.152.jar original/lsd.jar --outputdir lsd-src
   ```

### Optional: local baseline and diffs for `lsd-src`

Because `lsd-src/` is `.gitignore`d in the main repository, each developer maintains their own decompiled sources per PCM firmware. If you want to:

- Quickly reset `lsd-src` to a clean baseline between mods, and
- See diffs between your current edits and the original decompile,

you can initialize a **local-only Git repository inside `lsd-src/`** after your first decompile:

```bash
cd lsd-src
git init
git add .
git commit -m "baseline: decompile from my PCM lsd.jar"
git tag baseline
```

For future mods, instead of re-running CFR, you can reset back to the clean baseline instantly:

```bash
cd lsd-src
git reset --hard baseline
```

You can also inspect how a patch differs from the baseline decompile:

```bash
cd lsd-src
git diff baseline
# or restrict to just the files listed in patch-files.txt:
git diff baseline -- $(cat ../patch-files.txt)
```

This inner Git repo lives only on your machine (because `lsd-src/` is ignored by the outer repo) and gives you fast resets plus source-level diffs without re-decompiling.

---

## Branch Model

- The `main` branch holds the shared tooling and configuration. `lsd-src` is intentionally *not* tracked in Git and is always derived locally from your own `lsd.jar`.
- Each mod is developed on a dedicated branch named `patch/<mod-name>`.
- On a patch branch, you:
  - Modify source files under `lsd-src/`.
  - Maintain `patch-files.txt` listing source files included in the mod (paths relative to `lsd-src/`).
  - Use `patch-config.sh` (generic, shared across branches) which derives mod-specific variables from the current branch name.

Example:

```
patch/menu-facelift
patch/ui-enhancements
```

---

## Per-mod Configuration

Each patch branch must contain at its root:
- `patch-files.txt` listing one relative file path per line (relative to `lsd-src/`):
  ```
    de/audi/app/terminalmode/adi/ADITMConfiguration.java
    de/audi/tghu/terminalmode/hmi/pag2pg35/TerminalModeScreenBag1.java
  ```
---

## Development Workflow

The `scripts/dev/` directory contains scripts to manage patch builds:

1. **Prepare**

   Copies files listed in `patch-files.txt` from `lsd-src/` to the Gradle project source folder:

   ```bash
   ./scripts/dev/prepare.sh
   ```

2. **Build**

   Prepares and builds the patch jar in `patch-project/build/libs/`:

   ```bash
   ./scripts/dev/build.sh
   ```

   This runs `prepare.sh` and then:

   ```bash
   ./gradlew clean jar
   ```

   The output jar is named `${PATCH_JAR_BASENAME}.jar`.
   By default, `PATCH_JAR_BASENAME` is derived from the current branch name (e.g. `patch/menu-facelift` → `menu-facelift`).

3. **Validate**

   Validates the built jar by listing contents and showing diffs against the base branch:

   ```bash
   ./scripts/dev/validate.sh
   ```

---

## ModKit Workflow

To package a mod for ModKit installation, run:

```bash
./scripts/modkit/build.sh
```

This script:

- Uses the current git branch name (e.g. `patch/menu-facelift`).
- Creates a folder under `modkit/<mod-name>/` (e.g. `modkit/menu-facelift/`).
- Copies the built jar to `modkit/<mod-name>/Update/<PATCH_JAR_BASENAME>.jar`.
- Generates an Update `install.sh`, `uninstall.sh`, and `README.md` in the mod folder based on templates in `modkit/templates/`, replacing `{JAR_NAME}` and `{MOD_NAME}` placeholders.

---

## Tips / Gotchas

- **Java Version:** The patch project compiles with Java 8 tooling but targets Java 1.4 bytecode (`sourceCompatibility=1.4`, `targetCompatibility=1.4`). Avoid using Java features newer than 1.4.

- **Patch Files:** Always keep `patch-files.txt` updated with all source files your mod modifies or adds.

- **Local `lsd-src` Only:** `lsd-src/` and `original/lsd.jar` are intentionally `.gitignore`d. Each developer should decompile their own `lsd.jar` and may use a local Git repo inside `lsd-src/` (with a `baseline` tag) to manage clean resets and diffs.

- **Branch Hygiene:** Use one branch per mod to keep patches isolated and easily maintainable.

- **Decompilation Issues:** If CFR throws errors, the unzip/re-jar step usually fixes corrupted jar headers.

- **ModKit Scripts:** The install/uninstall scripts generated by `./scripts/modkit/build.sh` are basic and may require manual adjustments for complex mods.

- **Building from Scratch:** After updating `lsd-src/`, always run `./scripts/dev/build.sh` to produce a fresh patch jar.

- **Diff Validation:** Use `./scripts/dev/validate.sh` to check that your patch files differ only where expected against the base branch.

---

This repository is designed to streamline MH2P LSD mod development by providing a clear, repeatable process for decompilation, patching, building, and packaging mods for MH2p SD ModKit distribution.