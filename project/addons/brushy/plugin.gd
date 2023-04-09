# Copyright © 2021 Josh Jones and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
@tool
extends EditorPlugin


var undo_redo: EditorUndoRedoManager;
var brush_gizmo_plugin: BrushGizmoPlugin;


func _enter_tree() -> void:
	undo_redo = get_undo_redo();

	brush_gizmo_plugin = BrushGizmoPlugin.new(undo_redo);
	add_node_3d_gizmo_plugin(brush_gizmo_plugin);


func _exit_tree() -> void:
	add_node_3d_gizmo_plugin(brush_gizmo_plugin);
