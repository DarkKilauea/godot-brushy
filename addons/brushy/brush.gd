tool
class_name Brush
extends Spatial


var mesh_instance := MeshInstance.new();

var collision_parent: CollisionObject;
var collision_owner_id := -1;
var collision_enabled := true setget _set_collision_enabled;
var collision_shape: Shape setget _set_collision_shape;

var default_material = SpatialMaterial.new();
var faces := [
	BrushFace.new(Plane(Vector3.FORWARD, 1.0), default_material, Transform2D.IDENTITY),
	BrushFace.new(Plane(Vector3.BACK, 1.0), default_material, Transform2D.IDENTITY),
	BrushFace.new(Plane(Vector3.LEFT, 1.0), default_material, Transform2D.IDENTITY),
	BrushFace.new(Plane(Vector3.RIGHT, 1.0), default_material, Transform2D.IDENTITY),
	BrushFace.new(Plane(Vector3.UP, 1.0), default_material, Transform2D.IDENTITY),
	BrushFace.new(Plane(Vector3.DOWN, 1.0), default_material, Transform2D.IDENTITY)
];


func _init() -> void:
	add_child(mesh_instance);


func _ready() -> void:
	set_notify_transform(true);
	_update_meshes();


func _get_property_list() -> Array:
	return [
		{
			"name": "Brush",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_CATEGORY
		},
		{
			"name": "Collision",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			"hint_string": "collision_"
		},
		{
			"name": "collision_enabled",
			"type": TYPE_BOOL
		}
	];


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			collision_parent = get_parent() as CollisionObject;
			if (collision_parent):
				collision_owner_id = collision_parent.create_shape_owner(self);
				if (collision_shape):
					collision_parent.shape_owner_add_shape(collision_owner_id, collision_shape);
				
				collision_parent.shape_owner_set_transform(collision_owner_id, transform);
				collision_parent.shape_owner_set_disabled(collision_owner_id, !collision_enabled);
				collision_parent.update_gizmo();
		
		NOTIFICATION_UNPARENTED:
			if (collision_parent):
				collision_parent.remove_shape_owner(collision_owner_id);
				collision_parent.update_gizmo();
			
			collision_owner_id = -1;
			collision_parent = null;
		
		NOTIFICATION_ENTER_TREE:
			if (collision_parent):
				collision_parent.shape_owner_set_transform(collision_owner_id, transform);
				collision_parent.shape_owner_set_disabled(collision_owner_id, !collision_enabled);
				collision_parent.update_gizmo();
		
		NOTIFICATION_TRANSFORM_CHANGED:
			if (collision_parent):
				collision_parent.shape_owner_set_transform(collision_owner_id, transform);
				collision_parent.update_gizmo();


func _set_collision_enabled(value: bool) -> void:
	collision_enabled = value;
	update_gizmo();
	
	if (collision_parent):
		collision_parent.shape_owner_set_disabled(collision_owner_id, !collision_enabled);
		collision_parent.update_gizmo();


func _set_collision_shape(value: Shape) -> void:
	if (collision_shape == value):
		return;
	
	collision_shape = value;
	update_gizmo();
	
	if (collision_parent):
		collision_parent.shape_owner_clear_shapes(collision_owner_id);
		if (collision_shape):
			collision_parent.shape_owner_add_shape(collision_owner_id, collision_shape);
		collision_parent.update_gizmo();


func _update_meshes() -> void:
	var collision_vertices := PoolVector3Array();
	
	var surface_tool := SurfaceTool.new();
	var visual_mesh := ArrayMesh.new();
	
	for i in range(faces.size()):
		var face: BrushFace = faces[i];
		var face_vertices := PoolVector3Array();
		
		print(face);
		surface_tool.clear();
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP);
		surface_tool.set_material(face.material);
		
		for j in range(faces.size()):
			for k in range(faces.size()):
				var face2: BrushFace = faces[j];
				var face3: BrushFace = faces[k];
			
				var vertex = face.plane.intersect_3(face2.plane, face3.plane);
				if vertex and _vertex_in_hull(vertex):
					
					# Check for duplicate
					var unique_vertex := true;
					for other_vertex in face_vertices:
						if other_vertex.is_equal_approx(vertex):
							unique_vertex = false;
							break;
					
					if unique_vertex:
						print(vertex);
						face_vertices.append(vertex);
						collision_vertices.append(vertex);
						
						surface_tool.add_normal(face.plane.normal);
						surface_tool.add_vertex(vertex);
		
		surface_tool.commit(visual_mesh);
	
	
	mesh_instance.mesh = visual_mesh;
	
	var shape := ConvexPolygonShape.new();
	shape.points = collision_vertices;
	self.collision_shape = shape;


func _vertex_in_hull(vertex: Vector3) -> bool:
	for face in faces:
		var plane: Plane = face.plane;
		if plane.is_point_over(vertex):
			return false;
	
	return true;


class BrushFace:
	var plane: Plane;
	var material: Material;
	var texture_transform: Transform2D;
	
	func _init(p_plane: Plane, p_material: Material, p_transform: Transform2D) -> void:
		plane = p_plane;
		material = p_material;
		texture_transform = p_transform;
