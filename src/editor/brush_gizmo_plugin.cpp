#include "brush_gizmo_plugin.h"

#include <godot_cpp/classes/geometry3d.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include "brush.h"

void BrushGizmoPlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_undo_redo_manager", "undo_redo_manager"), &BrushGizmoPlugin::set_undo_redo_manager);
}

// Workaround for doctool constructing the class to get info.
Ref<StandardMaterial3D> BrushGizmoPlugin::_get_or_create_material(const String &name, const Ref<EditorNode3DGizmo> &gizmo) {
	Ref<StandardMaterial3D> material = get_material(name, gizmo);
	if (material.is_valid()) {
		return material;
	}

	if (name == "border") {
		create_material(name, Color::named("ORANGE"));
		return get_material(name, gizmo);
	} else if (name == "face_centers") {
		create_handle_material(name);
		return get_material(name, gizmo);
	} else {
		ERR_FAIL_V_MSG(material, "Unknown material: " + name);
	}
}

BrushGizmoPlugin::BrushGizmoPlugin() {
}

BrushGizmoPlugin::~BrushGizmoPlugin() {
}

void BrushGizmoPlugin::set_undo_redo_manager(EditorUndoRedoManager *p_undo_redo_manager) {
	undo_redo_manager = p_undo_redo_manager;
}

bool BrushGizmoPlugin::_has_gizmo(Node3D *for_node_3d) const {
	return Object::cast_to<Brush>(for_node_3d) != nullptr;
}

String BrushGizmoPlugin::_get_gizmo_name() const {
	return "Brush";
}

void BrushGizmoPlugin::_redraw(const Ref<EditorNode3DGizmo> &gizmo) {
	Brush *brush = Object::cast_to<Brush>(gizmo->get_node_3d());
	ERR_FAIL_NULL(brush);

	// HACK: gizmo is incorrected marked as const, need to remove the const qualifier.
	EditorNode3DGizmo *gizmo_nonconst = const_cast<EditorNode3DGizmo *>(gizmo.ptr());

	gizmo_nonconst->clear();
	PackedVector3Array centers;

	for (uint32_t i = 0; i < brush->get_face_count(); i++) {
		PackedVector3Array lines;
		centers.append(brush->get_face_center(i));

		PackedVector3Array vertex_positions = brush->get_face_vertex_positions(i);
		lines.append_array(vertex_positions);

		gizmo_nonconst->add_lines(lines, _get_or_create_material("border", gizmo));
		gizmo_nonconst->add_collision_segments(lines);
	}

	gizmo_nonconst->add_handles(centers, _get_or_create_material("face_centers", gizmo), PackedInt32Array());
}

String BrushGizmoPlugin::_get_handle_name(const Ref<EditorNode3DGizmo> &gizmo, int32_t handle_id, bool secondary) const {
	return "Face " + itos(handle_id) + " distance";
}

Variant BrushGizmoPlugin::_get_handle_value(const Ref<EditorNode3DGizmo> &gizmo, int32_t handle_id, bool secondary) const {
	Brush *brush = Object::cast_to<Brush>(gizmo->get_node_3d());
	ERR_FAIL_NULL_V(brush, Variant());

	return brush->get_face_plane(handle_id);
}

void BrushGizmoPlugin::_set_handle(const Ref<EditorNode3DGizmo> &gizmo, int32_t handle_id, bool secondary, Camera3D *camera, const Vector2 &screen_pos) {
	Brush *brush = Object::cast_to<Brush>(gizmo->get_node_3d());
	ERR_FAIL_NULL(brush);

	Transform3D brush_transform = brush->get_global_transform();
	Transform3D brush_inv_transform = brush_transform.affine_inverse();

	Vector3 ray_from = camera->project_ray_origin(screen_pos);
	Vector3 ray_dir = camera->project_ray_normal(screen_pos);

	ray_from = brush_inv_transform.xform(ray_from);
	Vector3 ray_to = brush_inv_transform.xform(ray_from + ray_dir * camera->get_far());

	Plane face_plane = brush->get_face_plane(handle_id);
	Vector3 origin = Vector3();
	Vector3 origin_from = origin + -face_plane.normal * camera->get_far();
	Vector3 origin_to = origin + face_plane.normal * camera->get_far();
	PackedVector3Array res_points = Geometry3D::get_singleton()->get_closest_points_between_segments(origin_from, origin_to, ray_from, ray_to);
	Vector3 new_pos = res_points[0];
	real_t new_distance = new_pos.distance_to(origin);

	if (!Plane(face_plane.normal, 0).is_point_over(new_pos)) {
		new_distance = -new_distance;
	}

	// TODO: Enable support for snapping.
	//if (spatial_editor.is_snap_enabled()){
	//	new_distance = stepify(new_distance, spatial_editor.get_translate_snap());
	//}

	brush->set_face_plane(handle_id, Plane(face_plane.normal, new_distance));
}

void BrushGizmoPlugin::_commit_handle(const Ref<EditorNode3DGizmo> &gizmo, int32_t handle_id, bool secondary, const Variant &restore, bool cancel) {
	Brush *brush = Object::cast_to<Brush>(gizmo->get_node_3d());
	ERR_FAIL_NULL(brush);

	if (cancel) {
		brush->set_face_plane(handle_id, restore);
		return;
	}

	if (undo_redo_manager) {
		undo_redo_manager->create_action("Update Face Distance");
		undo_redo_manager->add_do_method(brush, "set_face_plane", handle_id, brush->get_face_plane(handle_id));
		undo_redo_manager->add_undo_method(brush, "set_face_plane", handle_id, restore);
		undo_redo_manager->commit_action();
	}
}
