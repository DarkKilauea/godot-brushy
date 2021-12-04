tool
class_name BrushFace
extends Reference


# TODO: Replace with a project setting.  Sets the number of texels that fit in one "unit".
const DEFAULT_TEXEL_DENSITY := Vector2(1024, 1024);
const cardinal_axis = [
	[Vector3.FORWARD, Vector3.LEFT, Vector3.DOWN],
	[Vector3.RIGHT, Vector3.FORWARD, Vector3.DOWN],
	[Vector3.BACK, Vector3.RIGHT, Vector3.DOWN],
	[Vector3.LEFT, Vector3.BACK, Vector3.DOWN],
	[Vector3.UP, Vector3.RIGHT, Vector3.BACK],
	[Vector3.DOWN, Vector3.RIGHT, Vector3.FORWARD],
];


var plane: Plane;
var material: Material;
var uv_transform: Transform2D;
var skip: bool;

## Surface data
var center: Vector3;
var tangent_basis: Basis;
var vertices: Array;


func build_surface_data(faces: Array) -> void:
	center = Vector3.ZERO;
	tangent_basis = _calc_tangent_basis();
	vertices.clear();
	
	for j in range(faces.size()):
		for k in range(faces.size()):
			var face2: BrushFace = faces[j];
			var face3: BrushFace = faces[k];
		
			var vertex = plane.intersect_3(face2.plane, face3.plane);
			if vertex and _vertex_in_hull(vertex, faces):
				
				# Check for duplicate
				var unique_vertex := true;
				for other_vertex in vertices:
					if other_vertex.position.is_equal_approx(vertex):
						unique_vertex = false;
						break;
				
				if unique_vertex:
					var brush_vertex := BrushVertex.new();
					brush_vertex.position = vertex;
					brush_vertex.normal = plane.normal;
					brush_vertex.uv = _calc_uv(vertex, tangent_basis);
					
					vertices.append(brush_vertex);
					center += vertex;
	
	if !vertices.empty():
		center /= vertices.size();
	
	_fix_winding_order();


func _vertex_in_hull(vertex: Vector3, faces: Array) -> bool:
	for face in faces:
		var plane: Plane = face.plane;
		if plane.is_point_over(vertex):
			return false;
	
	return true;


func _calc_tangent_basis() -> Basis:
	var best_axis: Array;
	var best_dot_product: float;
	
	# Figure out basis vectors for UV coordinates by matching our normal against cardinal directions.
	for face_axis in cardinal_axis:
		var facing_dir: Vector3 = face_axis[0];
		var dot_product := plane.normal.dot(facing_dir);
		if (dot_product > best_dot_product):
			best_dot_product = dot_product;
			best_axis = face_axis;
	
	return Basis(best_axis[1], best_axis[2], best_axis[0]);


func _calc_uv(vertex: Vector3, tangent_basis: Basis) -> Vector2:
	# Figure out texture size.
	var texture_size := Vector2(1, 1);
	var spatial_material := material as SpatialMaterial;
	if (spatial_material && spatial_material.albedo_texture):
		texture_size = spatial_material.albedo_texture.get_size();
	
	texture_size /= DEFAULT_TEXEL_DENSITY;
	
	var uv := Vector2(tangent_basis.x.dot(vertex), tangent_basis.y.dot(vertex));
	
	# Scale by texture size.
	uv /= texture_size;
	
	# Scale by transform.
	uv /= uv_transform.get_scale();
	
	# Translate
	uv += uv_transform.get_origin() / texture_size;
	return uv;


# Ensure vertices are sorted in the correct winding order.
func _fix_winding_order() -> void:
	if vertices.size() < 3:
		return;
	
	var sorter := WindingSorter.new();
	sorter.face_basis = vertices[1].position - vertices[0].position;
	sorter.face_normal = plane.normal;
	sorter.face_center = center;
	
	vertices.sort_custom(sorter, "sort");


# Sorts verticies in winding order (clockwise).
# Adapted from https://github.com/QodotPlugin/libmap/blob/master/src/c/geo_generator.c
class WindingSorter:
	var face_basis: Vector3;
	var face_normal: Vector3;
	var face_center: Vector3;
	
	func sort(p_lhs: BrushVertex, p_rhs: BrushVertex):
		var u := face_basis.normalized();
		var v := u.cross(face_normal).normalized();
		
		var local_lhs := p_lhs.position - face_center;
		var lhs_pu := local_lhs.dot(u);
		var lhs_pv := local_lhs.dot(v);
		var lhs_angle := atan2(lhs_pv, lhs_pu);
		
		var local_rhs := p_rhs.position - face_center;
		var rhs_pu := local_rhs.dot(u);
		var rhs_pv := local_rhs.dot(v);
		var rhs_angle := atan2(rhs_pv, rhs_pu);
		
		if lhs_angle > rhs_angle:
			return false;
		else:
			return true;
