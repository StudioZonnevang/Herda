gras serves as the primary food source for a [[schaap]].

## Mechanics
The gras in a region is managed by a gras object (gras_manager.gd) that maintains a single value texture of the grass lengths.
Other entities that want to check or affect (eat) the grass do so by calling the gras managers functions.

## Rendering
The gras texture is read by a gras rendering object (gras_mesh.gd) that uses it to display the correct amount and height of gpu-instanced gras meshes.