<p align="center">
  <img src="assets/icon.png" width="164" height="164" alt="Desktop Labels icon">
</p>

# Desk Plate

A lightweight menu bar app that shows a floating label identifying your current desktop/space. Give your spaces memorable names to keep track of your work.
Built for macOS 26 (Tahoe).

<p align="center">
  <img src="assets/main-window.png" width="350" alt="Edit Labels window" valign="middle">
  <img src="assets/screenshot.png" width="400" alt="Floating glass label on desktop" valign="middle">
</p>



## Features

- **Floating glass label** overlay showing the current desktop name, rendered with Liquid Glass
- **Custom names** for each desktop space
- **SF Symbol icons** per desktop, chosen from a curated picker with 80+ icons across 9 categories
- **Flexible positioning** -- place the label in any corner or display it directly in the menu bar
- **Persistent settings** -- labels, icons, and position survive restarts

## Installation

```bash
make
```

This compiles all Swift sources, bundles the app, and ad-hoc codesigns it.

To build and install to `~/Applications`:

```bash
make install
```

### Requirements

- macOS 26 (Tahoe) or later
- Xcode Command Line Tools (for `swiftc` and the macOS SDK)

## Usage

- **Left-click** the menu bar icon to open the Edit Labels window
- **Right-click** the menu bar icon for the dropdown menu (position, quit)
- Assign a name and optional icon to each desktop
- Choose where the label appears: Top Left, Top Right, Bottom Left, Bottom Right, or In Menu Bar

    
## See Also

- [Spaceman](https://github.com/Jaysce/Spaceman) -- view your Spaces in the menu bar (also available as a [maintained fork](https://github.com/ruittenb/Spaceman))
- [DesktopRenamer](https://github.com/gitmichaelqiu/DesktopRenamer) -- rename macOS desktops/spaces, shown as a menu bar label
- [Spaces Renamer](https://github.com/dado3212/spaces-renamer) -- rename spaces directly in Mission Control (requires SIP disabled; Intel only)

## Author

James Bagrow

## License

MIT License

Copyright (c) 2026 James Bagrow

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
