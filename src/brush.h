#pragma once

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/collision_object3d.hpp>
#include <godot_cpp/classes/convex_polygon_shape3d.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/templates/local_vector.hpp>

using namespace godot;

class Brush : public Node3D {
	GDCLASS(Brush, Node3D);

	struct Vertex {
		Vector3 position;
		Vector3 normal;
		Vector2 uv;
	};

	struct Face {
		Plane plane;
		Ref<Material> material;
		Transform2D uv_transform;
		bool skip = false;

		// Surface data
		Vector3 center;
		Basis uv_basis;
		LocalVector<Vertex> vertices;

		void _build_surface_data(const LocalVector<Face> &otherFaces);
		bool _vertex_in_hull(const Vector3 &vertex, const LocalVector<Face> &otherFaces) const;
		Basis _calc_tangent_basis() const;
		Vector2 _calc_uv(const Vector3 &vertex, Basis uv_basis) const;
		void _fix_winding_order();
	};

	bool collision_enabled = true;
	Ref<ConvexPolygonShape3D> collision_shape = nullptr;
	uint32_t collision_owner_id = 0;
	CollisionObject3D *collision_parent = nullptr;

	bool visual_enabled = true;
	Ref<Mesh> visual_mesh = nullptr;
	MeshInstance3D *visual_mesh_instance = nullptr;

	Vector3 center;
	bool faces_dirty = false;
	LocalVector<Face> faces;

protected:
	static void _bind_methods();
	void _get_property_list(List<PropertyInfo> *p_list) const;
	bool _set(const StringName &p_name, const Variant &p_value);
	bool _get(const StringName &p_name, Variant &r_ret) const;
	void _notification(int p_what);

	void _update_in_shape_owner(bool p_xform_only = false);

	void _set_collision_shape(const Ref<ConvexPolygonShape3D> &p_shape);
	void _set_visual_mesh(const Ref<Mesh> &p_mesh);

	Ref<ConvexPolygonShape3D> _build_collision_shape() const;
	Ref<ArrayMesh> _build_visual_mesh() const;

	void _mark_faces_dirty();
	void _update_meshes();

public:
	Brush();
	~Brush() override;

	void set_collision_enabled(bool p_enabled);
	bool is_collision_enabled() const { return collision_enabled; }

	Ref<ConvexPolygonShape3D> get_collision_shape() const { return collision_shape; }

	void set_visual_enabled(bool p_enabled);
	bool is_visual_enabled() const { return visual_enabled; }

	Ref<Mesh> get_visual_mesh() const { return visual_mesh; }

	uint32_t get_face_count() const { return faces.size(); }

	void set_face_plane(int p_face_index, const Plane &p_plane);
	Plane get_face_plane(int p_face_index) const;

	void set_face_material(int p_face_index, const Ref<Material> &p_material);
	Ref<Material> get_face_material(int p_face_index) const;

	void set_face_uv_transform(int p_face_index, const Transform2D &p_uv_transform);
	Transform2D get_face_uv_transform(int p_face_index) const;

	void set_face_skip(int p_face_index, bool p_skip);
	bool get_face_skip(int p_face_index) const;

	Vector3 get_face_center(int p_face_index) const;
	Basis get_face_uv_basis(int p_face_index) const;

	PackedVector3Array get_face_vertex_positions(int p_face_index) const;
	PackedVector3Array get_face_vertex_normals(int p_face_index) const;
	PackedVector2Array get_face_vertex_uvs(int p_face_index) const;
};

class BoxBrush : public Brush {
	GDCLASS(BoxBrush, Brush);

	BoxBrush();
};

class CylinderBrush : public Brush {
	GDCLASS(CylinderBrush, Brush);

	CylinderBrush();
};
