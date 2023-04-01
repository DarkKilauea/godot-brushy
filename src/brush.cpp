#include "brush.h"

#include <godot_cpp/classes/base_material3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/geometry3d.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/surface_tool.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/templates/hash_map.hpp>
#include <godot_cpp/templates/hash_set.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <vector>

using namespace godot;

const Vector3 FORWARD = Vector3(0, 0, -1);
const Vector3 BACK = Vector3(0, 0, 1);
const Vector3 RIGHT = Vector3(1, 0, 0);
const Vector3 LEFT = Vector3(-1, 0, 0);
const Vector3 UP = Vector3(0, 1, 0);
const Vector3 DOWN = Vector3(0, -1, 0);

// clang-format off
const Vector3 cardinal_axis[6][3] = {
    {FORWARD, LEFT,    DOWN},
	{RIGHT,   FORWARD, DOWN},
	{BACK,    RIGHT,   DOWN},
	{LEFT,    BACK,    DOWN},
	{UP,      RIGHT,   BACK},
	{DOWN,    RIGHT,   FORWARD},
};
// clang-format on

void Brush::Face::_build_surface_data(const LocalVector<Face> &otherFaces) {
	center = Vector3();
	tangent_basis = _calc_tangent_basis();
	vertices.clear();

	for (const Face &face2 : otherFaces) {
		for (const Face &face3 : otherFaces) {
			Vector3 vertex;
			if (plane.intersect_3(face2.plane, face3.plane, &vertex) && _vertex_in_hull(vertex, otherFaces)) {
				// Check for duplicate
				bool unique_vertex = true;
				for (const Vertex &v : vertices) {
					if (v.position.is_equal_approx(vertex)) {
						unique_vertex = false;
						break;
					}
				}

				// If unique, add to vertices
				if (unique_vertex) {
					Vertex new_vertex;
					new_vertex.position = vertex;
					new_vertex.normal = plane.normal;
					new_vertex.uv = _calc_uv(vertex, tangent_basis);

					vertices.push_back(new_vertex);
					center += vertex;
				}
			}
		}
	}

	if (vertices.size() > 0) {
		center /= vertices.size();
		_fix_winding_order();
	}
}

bool Brush::Face::_vertex_in_hull(const Vector3 &vertex, const LocalVector<Face> &otherFaces) const {
	for (const Face &face : otherFaces) {
		if (face.plane.is_point_over(vertex)) {
			return false;
		}
	}

	return true;
}

Basis Brush::Face::_calc_tangent_basis() const {
	Vector3 best_axis[3];
	real_t best_dot_product = -1.0;

	for (int i = 0; i < 6; i++) {
		real_t dot_product = plane.normal.dot(cardinal_axis[i][0]);
		if (dot_product > best_dot_product) {
			best_dot_product = dot_product;

			best_axis[0] = cardinal_axis[i][0];
			best_axis[1] = cardinal_axis[i][1];
			best_axis[2] = cardinal_axis[i][2];
		}
	}

	return Basis(best_axis[1], best_axis[2], best_axis[0]);
}

Vector2 Brush::Face::_calc_uv(const Vector3 &vertex, Basis tangent_basis) const {
	// Figure out texture size
	Vector2 texture_size = Vector2(1.0, 1.0);
	Vector2 texel_density = ProjectSettings::get_singleton()->get_setting("brushy/default_texel_density", Vector2(1024.0, 1024.0));

	if (Object::cast_to<BaseMaterial3D>(material.ptr())) {
		Ref<BaseMaterial3D> base_material = material;
		Ref<Texture2D> texture = base_material->get_texture(BaseMaterial3D::TEXTURE_ALBEDO);
		if (texture.is_valid()) {
			texture_size = Vector2(texture->get_width(), texture->get_height());
		}
	}

	texture_size /= texel_density;

	// Calculate UV
	Vector2 uv = Vector2(tangent_basis[0].dot(vertex), tangent_basis[1].dot(vertex));

	// Scale by texture size
	Transform2D texture_transform = uv_transform.scaled(Size2(1.0 / texture_size.x, 1.0 / texture_size.y));

	uv = texture_transform.xform(uv);
	return uv;
}

void Brush::Face::_fix_winding_order() {
	if (vertices.size() < 3) {
		return;
	}

	Vector3 face_basis;
	Vector3 face_normal;
	Vector3 face_center;

	// TODO: Remove need for std::vector
	std::vector<Vertex> vertices_copy;
	vertices_copy.reserve(vertices.size());
	for (const Vertex &v : vertices) {
		vertices_copy.push_back(v);
	}

	std::sort(vertices_copy.begin(), vertices_copy.end(), [face_basis, face_normal, face_center](const Vertex &p_lhs, const Vertex &p_rhs) {
		Vector3 u = face_basis.normalized();
		Vector3 v = u.cross(face_normal).normalized();

		Vector3 local_lhs = p_lhs.position - face_center;
		float lhs_pu = local_lhs.dot(u);
		float lhs_pv = local_lhs.dot(v);
		float lhs_angle = atan2(lhs_pv, lhs_pu);

		Vector3 local_rhs = p_rhs.position - face_center;
		float rhs_pu = local_rhs.dot(u);
		float rhs_pv = local_rhs.dot(v);
		float rhs_angle = atan2(rhs_pv, rhs_pu);

		if (lhs_angle > rhs_angle)
			return false;
		else
			return true;
	});

	for (int i = 0; i < vertices.size(); i++) {
		vertices[i] = vertices_copy[i];
	}
}

void Brush::_bind_methods() {
	ClassDB::bind_method(D_METHOD("_update_meshes"), &Brush::_update_meshes);

	ClassDB::bind_method(D_METHOD("set_collision_enabled", "enabled"), &Brush::set_collision_enabled);
	ClassDB::bind_method(D_METHOD("is_collision_enabled"), &Brush::is_collision_enabled);

	ClassDB::bind_method(D_METHOD("get_collision_shape"), &Brush::get_collision_shape);

	ClassDB::bind_method(D_METHOD("set_visual_enabled", "enabled"), &Brush::set_visual_enabled);
	ClassDB::bind_method(D_METHOD("is_visual_enabled"), &Brush::is_visual_enabled);

	ClassDB::bind_method(D_METHOD("get_visual_mesh"), &Brush::get_visual_mesh);

	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "collision_enabled"), "set_collision_enabled", "is_collision_enabled");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "visual_enabled"), "set_visual_enabled", "is_visual_enabled");
}

void Brush::_notification(int what) {
	switch (what) {
		case NOTIFICATION_PARENTED: {
			collision_parent = Object::cast_to<CollisionObject3D>(get_parent());
			if (collision_parent) {
				collision_owner_id = collision_parent->create_shape_owner(this);
				if (collision_shape.is_valid()) {
					collision_parent->shape_owner_add_shape(collision_owner_id, collision_shape);
				}

				_update_in_shape_owner();
			}
		} break;
		case NOTIFICATION_UNPARENTED: {
			if (collision_parent) {
				collision_parent->remove_shape_owner(collision_owner_id);
				collision_parent->update_gizmos();
			}

			collision_owner_id = 0;
			collision_parent = nullptr;
		} break;
		case NOTIFICATION_ENTER_TREE: {
			if (collision_parent) {
				_update_in_shape_owner();
			}

		} break;
		case NOTIFICATION_READY: {
			visual_mesh_instance = memnew(MeshInstance3D);
			visual_mesh_instance->set_gi_mode(GeometryInstance3D::GI_MODE_STATIC);
			add_child(visual_mesh_instance);
		} break;
		case NOTIFICATION_LOCAL_TRANSFORM_CHANGED: {
			if (collision_parent) {
				_update_in_shape_owner(true);
			}
#ifdef TOOLS_ENABLED
			if (Engine::get_singleton()->is_editor_hint()) {
				update_configuration_warnings();
			}
#endif
		} break;
	}
}

void Brush::_update_in_shape_owner(bool p_xform_only) {
	collision_parent->shape_owner_set_transform(collision_owner_id, get_transform());
	if (p_xform_only) {
		return;
	}
	collision_parent->shape_owner_set_disabled(collision_owner_id, !collision_enabled);
	collision_parent->update_gizmos();
}

void Brush::_set_collision_shape(const Ref<Shape3D> &p_shape) {
	if (collision_shape == p_shape) {
		return;
	}

	collision_shape = p_shape;

	if (collision_parent) {
		collision_parent->shape_owner_clear_shapes(collision_owner_id);
		if (collision_shape.is_valid()) {
			collision_parent->shape_owner_add_shape(collision_owner_id, collision_shape);
		}

		collision_parent->update_gizmos();
	}
}

void Brush::_set_visual_mesh(const Ref<Mesh> &p_mesh) {
	if (visual_mesh == p_mesh) {
		return;
	}

	visual_mesh = p_mesh;
	visual_mesh_instance->set_mesh(visual_mesh);
}

Ref<ConvexPolygonShape3D> Brush::_build_collision_shape() const {
	// Gather unique vertices
	HashSet<Vector3> collision_vertices;
	for (Face face : faces) {
		for (Vertex vertex : face.vertices) {
			collision_vertices.insert(vertex.position);
		}
	}

	// Convert to PackedVector3Array
	PackedVector3Array points;
	points.resize(collision_vertices.size());
	for (Vector3 vertex : collision_vertices) {
		points.push_back(vertex);
	}

	// Create shape
	Ref<ConvexPolygonShape3D> shape = Ref<ConvexPolygonShape3D>(memnew(ConvexPolygonShape3D));
	shape->set_points(points);
	return shape;
}

Ref<ArrayMesh> Brush::_build_visual_mesh() const {
	Ref<SurfaceTool> surface_tool = Ref<SurfaceTool>(memnew(SurfaceTool));
	Ref<ArrayMesh> mesh = Ref<ArrayMesh>(memnew(ArrayMesh));

	PackedVector3Array vertex_data;
	PackedVector2Array uv_data;
	PackedColorArray color_data;
	PackedVector2Array lightmap_uv_data;
	PackedVector3Array normal_data;
	TypedArray<Plane> tangent_data;

	// Group faces by their material
	HashSet<Ref<Material>> materials;
	HashMap<Ref<Material>, LocalVector<Face>> faces_by_material;
	for (Face face : faces) {
		if (face.skip) {
			continue;
		}

		if (!materials.has(face.material)) {
			materials.insert(face.material);
		}

		faces_by_material[face.material].push_back(face);
	}

	// Create a surface per material
	for (Ref<Material> material : materials) {
		surface_tool->clear();
		surface_tool->begin(Mesh::PRIMITIVE_TRIANGLES);
		surface_tool->set_material(material);

		for (Face face : faces_by_material[material]) {
			vertex_data.clear();
			uv_data.clear();
			color_data.clear();
			lightmap_uv_data.clear();
			normal_data.clear();
			tangent_data.clear();

			for (Vertex vertex : face.vertices) {
				vertex_data.append(vertex.position);
				uv_data.append(vertex.uv);
				normal_data.append(vertex.normal);
				tangent_data.append(face.plane);
			}

			surface_tool->add_triangle_fan(vertex_data, uv_data, color_data, lightmap_uv_data, normal_data, tangent_data);
		}

		surface_tool->commit(mesh);
	}

	return mesh;
}

void Brush::_mark_faces_dirty() {
	if (faces_dirty) {
		return;
	}

	faces_dirty = true;
	call_deferred("_update_meshes");
}

void Brush::_update_meshes() {
	// Update face data
	for (Face face : faces) {
		face._build_surface_data(faces);
	}

	// Calculate center
	center = Vector3();
	for (Face face : faces) {
		center += face.center;
	}

	if (faces.size() > 0) {
		center /= faces.size();
	}

	// Update visual mesh, if enabled
	if (visual_enabled) {
		_set_visual_mesh(_build_visual_mesh());
	} else {
		_set_visual_mesh(Ref<Mesh>());
	}

	// Update collision shape
	_set_collision_shape(_build_collision_shape());

	update_gizmos();
	faces_dirty = false;
}

Brush::Brush() {
	set_notify_local_transform(true);
}

Brush::~Brush() {
}

void Brush::set_collision_enabled(bool p_enabled) {
	if (collision_enabled == p_enabled) {
		return;
	}

	collision_enabled = p_enabled;

	_update_in_shape_owner();
}

void Brush::set_visual_enabled(bool p_enabled) {
	if (visual_enabled == p_enabled) {
		return;
	}

	visual_enabled = p_enabled;

	if (visual_enabled) {
		_set_visual_mesh(_build_visual_mesh());
	} else {
		_set_visual_mesh(Ref<Mesh>());
	}
}

//////////////////////////////////////////////////////////////////////////

BoxBrush::BoxBrush() {
	TypedArray<Plane> planes = Geometry3D::get_singleton()->build_box_planes(Vector3(1, 1, 1));
	for (int i = 0; i < planes.size(); ++i) {
		Face face;
		face.plane = planes[i];

		faces.push_back(face);
	}

	_mark_faces_dirty();
}

//////////////////////////////////////////////////////////////////////////

CylinderBrush::CylinderBrush() {
	TypedArray<Plane> planes = Geometry3D::get_singleton()->build_cylinder_planes(1, 1, 16, Vector3::AXIS_Y);
	for (int i = 0; i < planes.size(); ++i) {
		Face face;
		face.plane = planes[i];

		faces.push_back(face);
	}

	_mark_faces_dirty();
}
