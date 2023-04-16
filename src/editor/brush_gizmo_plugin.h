#pragma once

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/editor_node3d_gizmo_plugin.hpp>
#include <godot_cpp/classes/editor_undo_redo_manager.hpp>

using namespace godot;

class BrushGizmoPlugin : public EditorNode3DGizmoPlugin {
	GDCLASS(BrushGizmoPlugin, EditorNode3DGizmoPlugin);

	EditorUndoRedoManager *undo_redo_manager = nullptr;

protected:
	static void _bind_methods();
	Ref<StandardMaterial3D> _get_or_create_material(const String &name, const Ref<EditorNode3DGizmo> &gizmo);

public:
	BrushGizmoPlugin();
	~BrushGizmoPlugin() override;

	void set_undo_redo_manager(EditorUndoRedoManager *p_undo_redo_manager);

	bool _has_gizmo(Node3D *for_node_3d) const override;
	String _get_gizmo_name() const override;
	void _redraw(const Ref<EditorNode3DGizmo> &gizmo) override;
	String _get_handle_name(const Ref<EditorNode3DGizmo> &gizmo, int32_t handle_id, bool secondary) const override;
	virtual Variant _get_handle_value(const Ref<EditorNode3DGizmo> &gizmo, int32_t handle_id, bool secondary) const override;
	virtual void _set_handle(const Ref<EditorNode3DGizmo> &gizmo, int32_t handle_id, bool secondary, Camera3D *camera, const Vector2 &screen_pos) override;
	virtual void _commit_handle(const Ref<EditorNode3DGizmo> &gizmo, int32_t handle_id, bool secondary, const Variant &restore, bool cancel) override;
};