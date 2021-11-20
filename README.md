# Brushy

Provides tools for rapidly prototyping levels using convex polyhedrons.

This repository only contains the add-on and development resources.

## Features

- TODO

### Roadmap

- Creation of brushes
  - Block
  - Cylinder
  - Cone
  - Prism
  - Sphere
  - Arch?
  - Dome?
  - Torus?
  - Double Cone?
- Brush Manipulation
  - Vertex
    - Select
    - Move
    - Scale?
    - Snap to Grid?
  - Edge
    - Select
    - Move
    - Scale?
    - Split
  - Face
    - Select
    - Move
    - Scale?
  - Tools
    - Cut (split brush into two along a plane)
    - Carve (CSG Subtract)
    - Make Hollow (turn brush into room with walls)
    - Mirror Selection
      - X axis
      - Y axis
      - Z axis
- Texture Manipulation
  - Select Faces
  - Apply material to faces
  - Scale material
  - Shift material (X/Y)
  - Rotate material
  - Skew material
  - Align
    - Scale to fit
    - Scale to cover
    - Justify
      - Left
      - Center
      - Right
      - Top
      - Bottom
- Integration
  - Generate visual mesh
  - Generate physics shape
  - Generate occlusion meshes?


## Installation

### Using the Asset Library

- Open the Godot editor.
- Navigate to the **AssetLib** tab at the top of the editor and search for
  "Brushy".
- Install the
  [*Brushy*](https://godotengine.org/asset-library/asset/ASSETLIB_ID)
  plugin. Keep all files checked during installation.
- In the editor, open **Project > Project Settings**, go to **Plugins**
  and enable the **Brushy** plugin.

### Manual installation

Manual installation lets you use pre-release versions of this add-on by
following its `master` branch.

- Clone this Git repository:

```bash
git clone https://github.com/DarkKilauea/godot-brushy.git
```

Alternatively, you can
[download a ZIP archive](https://github.com/DarkKilauea/godot-brushy/archive/master.zip)
if you do not have Git installed.

- Move the `addons/` folder to your project folder.
- In the editor, open **Project > Project Settings**, go to **Plugins**
  and enable the **Brushy** plugin.

## Usage

USAGE

## License

Copyright © 2021 Josh Jones and contributors

Unless otherwise specified, files in this repository are licensed under the
MIT license. See [LICENSE.md](LICENSE.md) for more information.
