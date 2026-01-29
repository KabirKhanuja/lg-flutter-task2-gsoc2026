# Liquid Galaxy Controller App (Flutter)

## Overview

This project is a Flutter-based controller application designed to interact with a Liquid Galaxy (LG) rig.
The application allows a user to remotely control Google Earth running on an LG setup using SSH, SFTP, and HTTP-based KML loading.

The app provides the following core functionalities:
- Display a persistent Liquid Galaxy logo on the left screen of a 3-screen rig
- Load and render a 3D pyramid model using KML and DAE files
- Fly the camera to a predefined home city
- Clear logos from the LG screens
- Clear loaded KMLs from the LG system

The implementation follows standard Liquid Galaxy architecture and is aligned with prior reference implementations (notably Lucia's 2025 LG project).

---

## High-Level Architecture

The system operates across three layers:
1. **Flutter Client (Controller App)**
2. **LG Master Machine (lg1)**
3. **Google Earth Instances (LG Rigs)**

The Flutter app does not directly control Google Earth.
Instead, it communicates with the LG master machine (lg1) via SSH, which then controls Google Earth indirectly using files and commands.

---

## Core Concepts Required for the System to Work

### 1. Apache Web Root (`/var/www/html`)

`/var/www/html` is the Apache DocumentRoot on lg1.
- Any file placed inside this directory is automatically served over HTTP.
- Example mapping:

```
/var/www/html/pyramid.kml  →  http://lg1:81/pyramid.kml
```

This is critical because:
- Google Earth cannot read local files from Flutter
- Google Earth can fetch files over HTTP

Therefore:
- All KML files
- All 3D model files (.dae)

must exist inside `/var/www/html`.

---

### 2. SSH and SFTP Usage

#### SSH
SSH is used to:
- Execute commands on lg1
- Write control instructions
- Trigger Google Earth behaviors

Example:
```bash
echo "http://lg1:81/pyramid.kml" > /var/www/html/kmls.txt
```

#### SFTP
SFTP is used to:
- Upload files from Flutter to lg1
- Transfer KML and DAE files into `/var/www/html`

Example flow:
- Flutter reads `pyramid.kml` from assets
- SFTP uploads it to `/var/www/html/pyramid.kml`
- Google Earth later fetches it via HTTP

---

### 3. kmls.txt and query.txt (Control Mechanisms)

Liquid Galaxy provides two primary mechanisms for loading KML content:

#### kmls.txt (Network Link Control)
`/var/www/html/kmls.txt` is polled by Google Earth for persistent overlays and screen elements.
- Used primarily for logos and overlays
- Supports multiple URLs (one per line)
- Changes are reflected based on refresh intervals

#### query.txt (Dynamic Content Loading)
`/tmp/query.txt` is the recommended method for loading placemarks and 3D models.
- Supports flyto commands and camera positioning
- Better for dynamic content that includes LookAt tags
- Used for the pyramid model in this implementation

**Critical Implementation Detail:**

For 3D models with placemarks, query.txt provides superior control:
```bash
echo "http://lg1:81/kml/master.kml" > /tmp/query.txt
```

This is because:
- kmls.txt treats content as overlays
- query.txt properly handles placemark-based KML with camera controls
- Models with LookAt tags require query.txt for correct positioning

---

## Clearing KML Content

### The Challenge

Clearing 3D models and KML content from Liquid Galaxy is non-trivial because:
- Google Earth caches loaded content
- Simply removing files does not immediately clear the display
- Network links maintain references until explicitly updated

### Implemented Solution

The application uses a file overwrite strategy:

1. **Overwrite master.kml with empty KML:**
```dart
const emptyKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document></Document>
</kml>''';
```

2. **Write the empty content to the same file path:**
```dart
await sftp.open('/var/www/html/kml/master.kml', mode: write);
await file.write(emptyKml);
```

3. **Force Google Earth to reload:**
```bash
echo "exittour=true" > /tmp/query.txt &&
echo "http://lg1:81/kml/master.kml" > /tmp/query.txt
```

### Why This Works

- Using a fixed filename (master.kml) allows Google Earth to track the resource
- Overwriting with empty content removes all placemarks and models
- The `exittour=true` command ensures any active tour is terminated
- Reloading the URL forces Google Earth to fetch the updated (now empty) file
- The refresh interval in myplaces.kml ensures the change propagates

### Alternative Approaches Tested

The following approaches were tested but found less reliable:
- Deleting the KML file entirely (causes 404 errors)
- Writing empty string to query.txt (Google Earth retains previous content)
- Using planetariumoff command (inconsistent behavior)
- Flying to a distant location (does not unload the model)

---

## Critical Refresh Configuration (Very Important)

### 1. Pyramid KML Refresh (Master KML)

The pyramid is loaded via master KML, so refresh is required.

**Why refresh is needed**

Without refresh:
- The pyramid may persist even after clearing
- Changes may not reflect immediately

**Configuration**

In `myplaces.kml` on all rigs:
- Set refresh for the master KML to 4 seconds

Conceptually:
```xml
<refreshMode>onInterval</refreshMode>
<refreshInterval>4</refreshInterval>
```

This ensures:
- Pyramid appears when added
- Pyramid disappears when cleared

---

### 2. Logo KML Refresh (Slave KML)

The logo is displayed using a screen overlay on a single slave screen (left screen of a 3-screen rig).

**Requirements**
- Must refresh quickly to allow show/clear actions
- Should not affect performance

**Configuration**

For `slave_3.kml`:
- Refresh interval set to 1 second

This allows:
- Immediate logo visibility
- Reliable clearing without restarting Google Earth

---

## 3D Model (DAE) Configuration

### File Placement and Path Structure

The Liquid Galaxy system uses a specific directory structure within the Apache web root:
```
/var/www/html/kml/master.kml
/var/www/html/model_1.dae
```

**Important Path Discovery:**
During implementation, it was discovered that the master KML file must be placed in:
```
/var/www/html/kml/master.kml
```

Not in the root of `/var/www/html/`. This is accessed via:
```
http://lg1:81/kml/master.kml
```

The double-slash in the URL (`http://lg1:81//kml/master.kml`) may appear in some configurations but is automatically normalized by Apache.

### Upload Sequence

The correct upload sequence is critical:

1. Upload the DAE model file first:
```dart
await uploadModelFile(modelData, 'model_1.dae');
```

2. Then upload and load the KML file:
```dart
await showPyramid(kmlContent);
```

If the KML is loaded before the model file exists, Google Earth will fail to find the referenced model and display an error placeholder.

### KML Reference

Inside `pyramid.kml`:
```xml
<Link>
  <href>http://lg1:81/model_1.dae</href>
</Link>
```

**Important notes:**
- Relative paths may fail in LG
- Absolute HTTP paths are recommended
- File permissions must allow Apache access

Recommended permissions:
```bash
chmod 644 /var/www/html/model_1.dae
chown lg:lg /var/www/html/model_1.dae
```

---

## Persistent SSH Connectivity

To avoid frequent disconnects and failures:

### LG Machine Configuration

On lg1:
- SSH service must be stable
- Sufficient retry attempts should be allowed

Recommended practices:
- Increase SSH connection retry attempts
- Avoid aggressive SSH timeouts
- Ensure no firewall blocks port 22

The Flutter app also implements:
- Automatic reconnection
- Connection state handling
- Retry logic before executing commands

---

## Application Flow (Simplified)

1. User opens the Flutter app
2. App loads LG connection configuration from persistent storage
3. SSH connection is established to lg1
4. Connection status is displayed with real-time updates
5. User presses an action button:
   - **Logo** → Generates and writes slave_3.kml via SSH
   - **Pyramid** → Uploads model_1.dae via SFTP, uploads master.kml, writes to query.txt
   - **FlyTo** → Writes LookAt command to `/tmp/query.txt`
   - **Clear Logo** → Overwrites slave_3.kml with empty document
   - **Clear KML** → Overwrites master.kml with empty document, reloads via query.txt
6. Google Earth:
   - Polls query.txt and kml files based on refresh intervals
   - Fetches KML via HTTP from lg1:81
   - Fetches DAE model via HTTP
   - Renders the scene with proper camera positioning

### Connection Management

The application implements robust connection handling:
- Automatic connection on startup
- Connection state tracking (connecting, connected, disconnected)
- Automatic reconnection before executing commands
- Manual connection testing via settings screen
- Configuration persistence using shared preferences

### Error Handling

All SSH and SFTP operations include:
- Timeout handling (2-second connection timeout)
- Exception catching and user notification
- Automatic state updates on failure
- Detailed error messages in snackbars

---

## Technical Implementation Details

### Dependencies
- `dartssh2`: SSH and SFTP client for Dart/Flutter
- `shared_preferences`: Persistent configuration storage
- `flutter/services.dart`: Asset loading for KML and DAE files

### Project Structure
```
lib/
  app/
    app.dart              # Main app widget
    app_theme.dart        # Material 3 theme configuration
  models/
    lg_command.dart       # LG command models
  screens/
    home_screen.dart      # Main controller interface
  services/
    lg_ssh_service.dart   # SSH/SFTP operations
    kml/
      kml_loader.dart     # Asset loading utilities
  settings/
    lg_config_storage.dart      # Configuration persistence
    lg_connection_config.dart   # Configuration model
    settings_screen.dart        # Settings UI
  widgets/
    action_button.dart    # Reusable button component
  utils/
    constants.dart        # Application constants
```

### Key Design Decisions

1. **Fixed Filenames**: Using `master.kml` instead of timestamped filenames allows proper refresh behavior and reliable clearing.

2. **SFTP Over SSH Commands**: File uploads use SFTP rather than SSH echo commands for better reliability with binary files and large content.

3. **Connection Pooling**: A single SSH client is maintained and reused across operations to minimize connection overhead.

4. **Busy Flag**: A global busy flag prevents concurrent SSH operations that could cause command interleaving.

5. **Query.txt Over kmls.txt**: The pyramid uses query.txt because it includes a LookAt tag for camera positioning, which is better handled by the query mechanism.

### State Management

The application uses `StatefulWidget` with simple state management:
- Connection status enum (connecting, connected, disconnected)
- No external state management library required
- setState() for UI updates
- Async/await for all SSH operations

---

## Setup Instructions

### Prerequisites
- Working Liquid Galaxy rig (3 screens)
- Apache running on lg1 (port 81)
- SSH access to lg1
- Flutter SDK installed

### Steps
1. Clone the repository
2. Place KML and DAE files in `assets/kml`
3. Configure LG connection details in the app
4. Build a release APK
5. Install APK on Android device
6. Ensure:
   - Apache is running
   - `/var/www/html` is accessible
   - Refresh intervals are configured

---

## Deliverables for GSoC Submission
- Flutter source code
- `pyramid.kml` (created/customized)
- `model_1.dae`
- Release APK
- Demonstration video (face + screen)
- GitHub repository link
- Files uploaded to the designated GSoC Drive folder

---

## Notes
- The pyramid KML is either self-created or adapted from a referenced source (clearly stated in submission).
- The architecture strictly follows Liquid Galaxy best practices.
- No hardcoded assumptions are made about Google Earth internals; all control is external and file-based.
