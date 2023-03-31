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

## Usage

*Coming soon*

## Contributing

### Getting started:

1. Clone this repository with submodules.
    - `git clone --recurse-submodules https://github.com/DarkKilauea/godot-brushy.git` \
    - `cd godot-brushy`
2. Update to the latest `godot-cpp`.
    - `git submodule update --remote`
2. Build a debug binary for the current platform.
    - `scons`
3. Import, edit, and play `project/` using Godot Engine 4+.

### Repository structure:

- `project/` - Godot project boilerplate.
  - `addons/brushy/` - Files to be distributed to other projects.¹
  - `demo/` - Scenes and scripts for internal testing. Not strictly necessary.
- `src/` - Source code of this extension.
- `godot-cpp/` - Submodule needed for GDExtension compilation.

¹ Before distributing as an addon, all binaries for all platforms must be built and copied to the `bin/` directory. This is done automatically by GitHub Actions.

### Distributing on the Godot Asset Library with GitHub Actions:

1. Go to Repository→Actions and download the latest artifact.
2. Test the artifact by extracting the addon into a project.
3. Create a new release on GitHub, uploading the artifact as an asset.
4. On the asset, Right Click→Copy Link to get a direct file URL. Don't use the artifacts directly from GitHub Actions, as they expire.
5. When submitting/updating on the Godot Asset Library, Change "Repository host" to `Custom` and "Download URL" to the one you copied.

## License

Copyright © 2021 Josh Jones and contributors

Unless otherwise specified, files in this repository are licensed under the
MIT license. See [LICENSE.md](LICENSE.md) for more information.
