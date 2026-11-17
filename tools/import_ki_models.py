#!/usr/bin/env python3
"""Shrinks AI-generated GLB models (2 million triangles, 60 MB) to game size.

For every tools/ki_originals/<name>.glb (unrigged originals; Godot ignores tools/) it writes assets/models/ki_modelle/game/<name>.glb:
  - quadric edge-collapse decimation WITH texture (pymeshlab) down to TRIANGLES
  - only the colour texture, shrunk to TEXTURE_SIZE px (no normal / metal maps)
  - feet on the ground (y = 0), centred, scaled to the height given in HEIGHTS (metres)
Usage: python3 tools/import_ki_models.py [name ...]     (default: all)
Needs: pip install pymeshlab trimesh pillow numpy   (and libopengl0 + libglu1-mesa on Linux)
"""
import os
import sys

import numpy as np
import pymeshlab
import trimesh
from PIL import Image

Image.MAX_IMAGE_PIXELS = None
SRC = os.path.join(os.path.dirname(__file__), "ki_originals")
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "models", "ki_modelle", "game")
TRIANGLES = 15000
TEXTURE_SIZE = 1024
# Wanted height in metres (our figures: Wukong ~1.5, Bajie ~1.6, the sitting monk ~0.9).
HEIGHTS = {"wukong": 1.5, "bajie": 1.65, "monk_sitting": 0.9, "monk": 1.4}


def shrink(name, triangles=TRIANGLES):
    scene = trimesh.load(os.path.join(SRC, name + ".glb"), force="scene")
    geom = next(iter(scene.geometry.values()))
    material = geom.visual.material
    image = getattr(material, "baseColorTexture", None) or getattr(material, "image", None)
    if image is None:
        raise SystemExit(f"{name}: no colour texture found")
    image = image.convert("RGB")
    image.thumbnail((TEXTURE_SIZE, TEXTURE_SIZE))
    verts = np.asarray(geom.vertices, dtype=np.float64)
    faces = np.asarray(geom.faces, dtype=np.int32)
    uv = np.asarray(geom.visual.uv, dtype=np.float64)
    print(f"{name}: {len(faces)} triangles -> {triangles}")
    ms = pymeshlab.MeshSet()
    ms.add_mesh(pymeshlab.Mesh(vertex_matrix=verts, face_matrix=faces, v_tex_coords_matrix=uv))
    ms.apply_filter("compute_texcoord_transfer_vertex_to_wedge")
    ms.apply_filter("meshing_decimation_quadric_edge_collapse_with_texture", targetfacenum=triangles, preservenormal=True)
    mesh = ms.current_mesh()
    v = mesh.vertex_matrix()
    f = mesh.face_matrix()
    wedge = mesh.wedge_tex_coord_matrix().reshape(-1, 3, 2)
    # One vertex per face corner (so every corner keeps its own UV), then merge identical ones.
    corner_pos = v[f.reshape(-1)]
    corner_uv = wedge.reshape(-1, 2)
    out = trimesh.Trimesh(vertices=corner_pos, faces=np.arange(len(corner_pos)).reshape(-1, 3), process=False)
    out.visual = trimesh.visual.TextureVisuals(uv=corner_uv, material=trimesh.visual.material.PBRMaterial(
        baseColorTexture=image, metallicFactor=0.0, roughnessFactor=0.9, doubleSided=True))
    out.merge_vertices(merge_tex=True, merge_norm=True)
    lo, hi = out.bounds
    height = hi[1] - lo[1]
    scale = HEIGHTS.get(name, 1.5) / height
    out.apply_translation([-(lo[0] + hi[0]) / 2, -lo[1], -(lo[2] + hi[2]) / 2])
    out.apply_scale(scale)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".glb")
    out.export(path)
    print(f"   wrote {path}: {len(out.faces)} triangles, {os.path.getsize(path) / 1024:.0f} KB, height {HEIGHTS.get(name, 1.5)} m (scaled x{scale:.4f})")


if __name__ == "__main__":
    names = sys.argv[1:] or [os.path.basename(p)[:-4] for p in sorted(os.listdir(SRC)) if p.endswith(".glb")]
    for n in names:
        shrink(n)
