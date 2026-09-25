"""Township-specific Blender audit and bake utility.

Run through Blender with the approved source file already loaded. The script
never saves the .blend; generated files are written only to the requested
output directory.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def _arguments() -> argparse.Namespace:
    arguments = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--audit", action="store_true")
    parser.add_argument("--bake", action="store_true")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--width", type=int, default=3072)
    parser.add_argument("--only", choices=("background", "layers", "all"), default="all")
    return parser.parse_args(arguments)


def _collection_tree(collection: bpy.types.Collection) -> dict[str, object]:
    return {
        "name": collection.name,
        "objects": len(collection.objects),
        "children": [_collection_tree(child) for child in collection.children],
    }


def _recursive_objects(collection: bpy.types.Collection) -> set[bpy.types.Object]:
    objects = set(collection.objects)
    for child in collection.children:
        objects.update(_recursive_objects(child))
    return objects


def _world_bounds(objects: set[bpy.types.Object]) -> dict[str, list[float]]:
    corners: list[Vector] = []
    for obj in objects:
        if obj.type != "MESH":
            continue
        corners.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    return {
        "minimum": [min(point[axis] for point in corners) for axis in range(3)],
        "maximum": [max(point[axis] for point in corners) for axis in range(3)],
    }


def audit() -> None:
    scene = bpy.context.scene
    town = bpy.data.collections.get("TOWNSHIP_ROOT")
    asset_names = [
        "GREAT_HALL",
        "WORKSHOP",
        "HOMES",
        "MARKET_DISTRICT",
        "EXPEDITION_LODGE",
        "DEPARTURE_GATE",
    ]
    cameras = []
    for obj in bpy.data.objects:
        if obj.type != "CAMERA":
            continue
        cameras.append(
            {
                "name": obj.name,
                "location": list(obj.location),
                "rotation_euler": list(obj.rotation_euler),
                "orthographic": obj.data.type == "ORTHO",
                "ortho_scale": obj.data.ortho_scale,
                "hidden_render": obj.hide_render,
            }
        )
    payload = {
        "blender": bpy.app.version_string,
        "file": bpy.data.filepath,
        "scene": scene.name,
        "active_camera": scene.camera.name if scene.camera else None,
        "render_engine": scene.render.engine,
        "resolution": [scene.render.resolution_x, scene.render.resolution_y],
        "resolution_percentage": scene.render.resolution_percentage,
        "film_transparent": scene.render.film_transparent,
        "view_look": scene.view_settings.look,
        "objects": len(bpy.data.objects),
        "town_bounds": _world_bounds(_recursive_objects(town)) if town else None,
        "asset_objects": {
            name: [
                {"name": obj.name, "parent": obj.parent.name if obj.parent else None}
                for obj in bpy.data.collections[name].objects
            ]
            for name in asset_names
        },
        "collections": _collection_tree(scene.collection),
        "cameras": cameras,
    }
    print("TOWNSHIP_AUDIT=" + json.dumps(payload, separators=(",", ":")))


CAMERA_WIDTH_METRES = 56.0
CAMERA_GROUND_CENTRE = Vector((0.0, -2.5, 0.0))

LAYER_PREFIXES: dict[str, tuple[str, ...]] = {
    "great_hall": ("TSV_GreatHall_",),
    "workshop": ("TSV_Workshop_",),
    "nurse_hut": ("TSV_NurseHut_",),
    "home_b": ("TSV_HomeB_",),
    "fishers_stall": ("TSV_FishersStall_",),
    "fish_shed": ("TSV_FishShed_",),
    "net_shed": ("TSV_NetShed_",),
    "expedition_lodge": ("TSV_Lodge_",),
    "gate_bell": ("TSV_Gate_", "TSV_Bell_", "TSV_Route_Signpost"),
    "slide_foreground": ("TSV_Slide_Banks", "TSV_Slide_Deck", "TSV_Slide_Pennant"),
}


def _set_review_hidden(hidden: bool) -> None:
    review = bpy.data.collections.get("_REVIEW_ONLY_not_for_export")
    if review is not None:
        review.hide_render = hidden


def _configure_camera(width: int) -> None:
    scene = bpy.context.scene
    camera = bpy.data.objects["TSV_Cam_Gameplay"]
    scene.camera = camera
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = CAMERA_WIDTH_METRES

    direction = camera.matrix_world.to_quaternion() @ Vector((0.0, 0.0, -1.0))
    current_centre = camera.location + direction * (-camera.location.z / direction.z)
    camera.location.x += CAMERA_GROUND_CENTRE.x - current_centre.x
    camera.location.y += CAMERA_GROUND_CENTRE.y - current_centre.y

    scene.render.resolution_x = width
    scene.render.resolution_y = round(width * 9.0 / 16.0)
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_depth = "8"
    scene.render.engine = "BLENDER_EEVEE_NEXT"


def _render(path: Path, transparent: bool) -> None:
    scene = bpy.context.scene
    path.parent.mkdir(parents=True, exist_ok=True)
    scene.render.film_transparent = transparent
    scene.render.image_settings.color_mode = "RGBA" if transparent else "RGB"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    print(f"TOWNSHIP_BAKE={path}")


def _matches_prefix(obj: bpy.types.Object, prefixes: tuple[str, ...]) -> bool:
    return any(obj.name.startswith(prefix) for prefix in prefixes)


def bake(output: Path, width: int, only: str) -> None:
    _configure_camera(width)
    _set_review_hidden(True)
    town = bpy.data.collections["TOWNSHIP_ROOT"]
    town_objects = _recursive_objects(town)
    original_visibility = {obj: obj.hide_render for obj in town_objects}

    if only in ("background", "all"):
        for obj, hidden in original_visibility.items():
            obj.hide_render = hidden
        _render(output / "township_background.png", False)

    if only in ("layers", "all"):
        lights = _recursive_objects(bpy.data.collections["LIGHTS"])
        for layer_name, prefixes in LAYER_PREFIXES.items():
            for obj in town_objects:
                obj.hide_render = obj not in lights and not _matches_prefix(obj, prefixes)
            _render(output / f"township_{layer_name}.png", True)

    for obj, hidden in original_visibility.items():
        obj.hide_render = hidden


def main() -> None:
    args = _arguments()
    if args.audit:
        audit()
        return
    if args.bake:
        if args.output is None:
            raise SystemExit("--bake requires --output")
        bake(args.output.resolve(), args.width, args.only)
        return
    raise SystemExit("Pass --audit or --bake.")


if __name__ == "__main__":
    main()
