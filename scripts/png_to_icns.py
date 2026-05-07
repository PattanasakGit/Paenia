#!/usr/bin/env python3
import struct
from pathlib import Path

png = Path("build/icon-source-sips.png").read_bytes()
out = Path("build/Workbench Theme Studio.app/Contents/Resources/AppIcon.icns")

# Minimal ICNS containing a 1024px PNG payload. macOS accepts the "ic10" PNG
# element for Dock, Finder, and Stage Manager rendering.
payload = b"ic10" + struct.pack(">I", len(png) + 8) + png
icns = b"icns" + struct.pack(">I", len(payload) + 8) + payload
out.write_bytes(icns)
print(out)
