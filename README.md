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

### 3. kmls.txt (Master KML Loader)

`/var/www/html/kmls.txt` is continuously polled by Google Earth on the LG rig.
- When a URL is written to this file:

```
http://lg1:81/pyramid.kml
```

- Google Earth fetches and renders that KML

Clearing KMLs:
```bash
> /var/www/html/kmls.txt
```

This is how:
- Pyramid is shown
- Pyramid is removed

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

### File Placement

The 3D model file must be placed exactly at:
```
/var/www/html/model_1.dae
```

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
2. App loads LG connection configuration
3. SSH connection is established to lg1
4. User presses an action button:
   - **Logo** → Writes slave KML
   - **Pyramid** → Uploads KML + writes kmls.txt
   - **FlyTo** → Writes to `/tmp/query.txt`
5. Google Earth:
   - Polls kmls.txt
   - Fetches KML via HTTP
   - Fetches DAE via HTTP
   - Renders the scene

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
