# Copyright © 2021 Josh Jones and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
#
# This script is needed to make the `class_name` scripts visible in the
# Create New Node dialog once the plugin is enabled.
tool
extends EditorPlugin


const BrushGizmoPlugin = preload("res://addons/brushy/editor/brush_gizmo_plugin.gd");


var undo_redo: UndoRedo;
var brush_gizmo_plugin: BrushGizmoPlugin;


func _enter_tree() -> void:
	undo_redo = get_undo_redo();

	brush_gizmo_plugin = BrushGizmoPlugin.new(undo_redo);
	add_spatial_gizmo_plugin(brush_gizmo_plugin);


func _exit_tree() -> void:
	remove_spatial_gizmo_plugin(brush_gizmo_plugin);
