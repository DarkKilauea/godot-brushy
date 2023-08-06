#pragma once

#include <godot_cpp/classes/editor_plugin.hpp>
#include <godot_cpp/classes/editor_undo_redo_manager.hpp>

#include "brush_gizmo_plugin.h"

using namespace godot;

class BrushyEditorPlugin : public EditorPlugin {
	GDCLASS(BrushyEditorPlugin, EditorPlugin);

	EditorUndoRedoManager *undo_redo_manager = nullptr;
	Ref<BrushGizmoPlugin> brush_gizmo_plugin;

protected:
	static void _bind_methods();

public:
	BrushyEditorPlugin() {}
	~BrushyEditorPlugin() override {}

	void _enter_tree() override;
	void _exit_tree() override;
};