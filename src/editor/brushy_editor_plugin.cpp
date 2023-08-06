#include "brushy_editor_plugin.h"

void BrushyEditorPlugin::_bind_methods() {
}

void BrushyEditorPlugin::_enter_tree() {
	undo_redo_manager = get_undo_redo();

	brush_gizmo_plugin.instantiate();
	brush_gizmo_plugin->set_undo_redo_manager(undo_redo_manager);

	add_node_3d_gizmo_plugin(brush_gizmo_plugin);
}

void BrushyEditorPlugin::_exit_tree() {
	remove_node_3d_gizmo_plugin(brush_gizmo_plugin);

	brush_gizmo_plugin = Ref<BrushGizmoPlugin>();
	undo_redo_manager = nullptr;
}
