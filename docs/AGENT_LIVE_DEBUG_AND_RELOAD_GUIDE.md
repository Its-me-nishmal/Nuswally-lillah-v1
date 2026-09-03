# Fast Real-Time Agent Bridge: Analysis, Hot Reload & Live Debug

This guide documents the ultra-fast, zero-human-interaction workflow for future AI agents working in this repository. It avoids heavy Flutter CLI overhead and enables sub-second feedback loops.

---

## 1. Ultra-Fast Lint & Error Verification (Zero CPU / RAM Waste)

### Why NOT `flutter analyze`?
`flutter analyze` boots Gradle, Dart VM wrappers, and analysis daemons from scratch on every run, taking **15–25 seconds** and consuming significant memory on laptops with 8GB RAM.

### The Fast Direct Engine Bridge (Takes ~2–3 seconds):
Invoke the Dart SDK analyzer directly on target modified files or the `lib/` directory:

```powershell
# Check specific modified files (instant ~2s)
& "D:\flutter_windows_3.41.7-stable\flutter\bin\cache\dart-sdk\bin\dart.exe" analyze lib\screens\library_tab_body.dart lib\screens\aurad_category_screen.dart

# Check entire lib/ workspace (~4-5s)
& "D:\flutter_windows_3.41.7-stable\flutter\bin\cache\dart-sdk\bin\dart.exe" analyze lib
```

- **Exit Code 0** = `No issues found!`
- Automatically outputs line numbers, column numbers, and exact lint error IDs without prompting for interactive user input.

---

## 2. Programmatic Live Hot Reload & Hot Restart (Zero Human Interaction)

When a debug session is running on the device (wirelessly via ADB to Samsung Galaxy M10s or emulator), the **Flutter Dart Development Service (DDS)** daemon is live.

### Detecting the Active VM Service URI:
```powershell
(Get-CimInstance Win32_Process -Filter "Name = 'dart.exe' and CommandLine like '%development-service%'").CommandLine
```
*Example Output:* `--vm-service-uri=http://127.0.0.1:63989/i679hb-T0iM=/`

### Triggering Instant Live Hot Reload (Takes ~0.8s):
Call the `ext.flutter.reassemble` RPC method directly via HTTP GET:

```powershell
# 1. Fetch Main Isolate ID
$vm = Invoke-RestMethod -Uri "http://127.0.0.1:63989/i679hb-T0iM=/getVM"
$isolateId = $vm.result.isolates[0].id

# 2. Trigger Reassemble / Hot Reload
Invoke-RestMethod -Uri "http://127.0.0.1:63989/i679hb-T0iM=/ext.flutter.reassemble?isolateId=$isolateId"
```

### Triggering Live Hot Restart:
Restart the entire Flutter app state via the `hotRestart` service call on the active Flutter run session or by sending `R` to the active session.

---

## 3. Keyboard & IDE Shortcuts Quick Reference

| Action | Windows / IDE Shortcut | Terminal / Console Key |
| :--- | :--- | :--- |
| **Hot Reload** | `Ctrl + F5` | Press `r` in terminal running Flutter |
| **Hot Restart** | `Ctrl + Shift + F5` | Press `R` (Shift + r) in terminal |
| **Send Problems to Agent** | Click **`Send all to Agent`** button in the Problems tab | Sends all LSP diagnostics directly to chat |
| **Open Problems Panel** | `Ctrl + Shift + M` | N/A |
| **Toggle Debug Console** | `Ctrl + Shift + Y` | N/A |

---

## 4. Live Logcat Exception Streaming (Without Restarting Debug)

To view live crashes/exceptions happening on the connected Android device in real-time:

```powershell
adb -s 192.168.20.8:38508 logcat -d | Select-String -Pattern "flutter|Exception|Error" | Select-Object -Last 30
```

---

## 5. Self-Healing & Temporary Artifact Hygiene

To ensure the workspace, laptop disk, and phone storage remain completely lean and free from bloat:
1. **Automated Screenshot Deletion**:
   Whenever screenshots are captured from the phone via ADB for UI verification, delete them immediately after inspection:
   ```powershell
   adb -s 192.168.20.8:38508 shell "rm -f /sdcard/*.png /sdcard/Download/*.png"
   ```
2. **Scratch & Extraction Cache**:
   Temporary dumps or APK decompression files must live strictly in designated scratch paths and be pruned when tasks are completed.
3. **Continuous Self-Improvement**:
   Any new engine bridges, low-RAM tricks, or direct APIs discovered during tasks must be appended to this document and referenced in `.agents/AGENTS.md`.

---

## 6. Route Stack & Asset Cache Gotchas During Live Reload

1. **Route Constructor Persistence (Pushed Routes)**:
   - When a screen is pushed onto the Navigator stack (e.g. `AuradCategoryScreen` or `MoulidReaderScreen`), Flutter's Hot Reload re-executes `build()`, but does **NOT** re-run constructor arguments or initial route setup.
   - If an item in a parent list was redirected to a new dataset/screen, Hot Reload while the child screen is currently open will continue displaying the old route state.
   - **Resolution**: Pop back to the parent screen (`adb shell input keyevent 4`) before reloading, or request a Hot Restart (`Ctrl + Shift + F5` or 🔄 toolbar button) to rebuild the root navigation stack.


2. **Asset Manifest & In-Memory Gzip Eviction**:
   - When modifying files in `assets/data/*.json.gz`, running `ext.flutter.reassemble` might reuse Flutter's in-memory `rootBundle` asset cache.
   - To force the asset cache to refresh without restarting:
     ```powershell
     Invoke-RestMethod -Uri "http://127.0.0.1:<PORT>/<TOKEN>/ext.flutter.evict?isolateId=<ISOLATE_ID>&value=assets/data/target.json.gz"
     ```
   - For newly created asset files not previously listed in `pubspec.yaml`, a Hot Restart is required so the app reads the updated `AssetManifest.bin`.

---

## 7. Zero-Screenshot Live Widget & Screen Inspection (Dart VM Service RPC)

To inspect active screens, widget hierarchies, buttons, and state without taking any screenshots or using disk storage:

### Querying the Live Root Widget Summary Tree:
```powershell
# 1. Detect Active VM Service URI
$uri = (Get-CimInstance Win32_Process -Filter "Name = 'dart.exe' and CommandLine like '%development-service%'").CommandLine | Select-String -Pattern "--vm-service-uri=([^\s]+)" | ForEach-Object { $_.Matches.Groups[1].Value }

# 2. Get Isolate ID
$vm = Invoke-RestMethod -Uri "${uri}getVM"
$isolateId = $vm.result.isolates[0].id

# 3. Fetch Root Widget Summary Tree (Takes ~40ms, Zero Disk Space)
$tree = Invoke-RestMethod -Uri "${uri}ext.flutter.inspector.getRootWidgetSummaryTree?isolateId=$isolateId&objectGroup=live_inspect"
```

- **Speed**: Returns in ~40ms directly over HTTP/WebSocket.
- **Data Extracted**: Active screens (`MoulidReaderScreen`, `LibraryTabBody`), total widgets rendered, interactive buttons/taps, and properties.
- **Zero Artifacts**: Keeps device and laptop clean with zero screenshot file creation.

