tool
class_name Brush
extends Spatial


var collision_enabled := true setget _set_collision_enabled;
var collision_shape: Shape setget _set_collision_shape;
var collision_parent: CollisionObject;
var collision_owner_id := -1;

var visual_enabled := true setget _set_visual_enabled;
var visual_mesh: Mesh setget _set_visual_mesh;
var visual_mesh_instance := MeshInstance.new();

var faces_dirty := false;
var faces := [];


func _init() -> void:
	# TODO: Debug logic, remove when generating shapes via tool.
	#var planes := Geometry.build_cylinder_planes(1, 2, 12, Vector3.AXIS_Y);
	#var planes := Geometry.build_capsule_planes(1, 2, 6, 3, Vector3.AXIS_Y);
	var planes := Geometry.build_box_planes(Vector3(1, 1, 1));
	var default_material = SpatialMaterial.new();
	default_material.albedo_texture = preload("res://icon.png");
	
	for plane in planes:
		var face := BrushFace.new(plane, default_material, Transform2D.IDENTITY, false);
		faces.append(face);
	
	add_child(visual_mesh_instance);
	set_notify_transform(true);


func _ready() -> void:
	# TODO: Remove this when we can save/load face data from scene.  Changing face data should mark dirty.
	mark_faces_dirty();


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
		},
		{
			"name": "collision_shape",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Shape"
		},
		{
			"name": "Visual",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			"hint_string": "visual_"
		},
		{
			"name": "visual_enabled",
			"type": TYPE_BOOL
		},
		{
			"name": "visual_mesh",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Mesh"
		},
		{
			"name": "face_data",
			"type": TYPE_ARRAY,
			"usage": PROPERTY_USAGE_NOEDITOR,
		}
	];


func _get(property: String):
	match property:
		"face_data":
			var data := [];
			for i in range(faces.size()):
				var face: BrushFace = faces[i];
				data.append(face.to_dictionary());
			
			return data;
	
	return null;


func _set(property: String, value) -> bool:
	match property:
		"face_data":
			faces.clear();
			
			for data in value:
				var face := _brush_face_from_dictionary(data);
				if (face):
					faces.append(face);
			
			mark_faces_dirty();
			return true;
	
	return false;


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
	if (collision_enabled == value):
		return;
	
	collision_enabled = value;
	
	if (collision_parent):
		collision_parent.shape_owner_set_disabled(collision_owner_id, !collision_enabled);
		collision_parent.update_gizmo();


func _set_collision_shape(value: Shape) -> void:
	if (collision_shape == value):
		return;
	
	collision_shape = value;
	
	if (collision_parent):
		collision_parent.shape_owner_clear_shapes(collision_owner_id);
		if (collision_shape):
			collision_parent.shape_owner_add_shape(collision_owner_id, collision_shape);
		collision_parent.update_gizmo();


func _set_visual_enabled(value: bool) -> void:
	if (visual_enabled == value):
		return;
	
	visual_enabled = value;
	
	if (visual_enabled):
		self.visual_mesh = build_visual_mesh();
	else:
		self.visual_mesh = null;


func _set_visual_mesh(value: Mesh) -> void:
	if (visual_mesh == value):
		return;
	
	visual_mesh = value;
	visual_mesh_instance.mesh = value;
	property_list_changed_notify();


func mark_faces_dirty() -> void:
	if (faces_dirty):
		return;
	
	faces_dirty = true;
	call_deferred("_update_meshes");


func _update_meshes() -> void:
	_update_face_data();
	
	if (visual_enabled):
		self.visual_mesh = build_visual_mesh();
	else:
		self.visual_mesh = null;
	
	self.collision_shape = build_collision_shape();


func _update_face_data() -> void:
	var start_time := OS.get_ticks_usec();
	
	for face in faces:
		face.build_surface_data(faces);
	
	print_debug("Face data gen time: ", (OS.get_ticks_usec() - start_time) / 1000.0, "ms");
	faces_dirty = false;


# This has to be here due to a bug in GDScript preventing BrushFace from calling its own initializer.
static func _brush_face_from_dictionary(data: Dictionary) -> BrushFace:
	var plane = data.get("plane", null);
	var material = data.get("material", null);
	var uv_transform = data.get("uv_transform", Transform2D.IDENTITY);
	var skip = data.get("skip", false);
	
	if (!plane || !plane is Plane):
		return null;
	
	return BrushFace.new(plane, material, uv_transform, skip);


func build_visual_mesh() -> Mesh:
	var start_time := OS.get_ticks_usec();
	
	var surface_tool := SurfaceTool.new();
	var visual_mesh := ArrayMesh.new();
	
	# Group faces by their material
	var faces_by_material := Dictionary();
	for i in range(faces.size()):
		var face: BrushFace = faces[i];
		if (face.skip):
			continue;
		
		if (faces_by_material.has(face.material)):
			faces_by_material[face.material].append(face);
		else:
			faces_by_material[face.material] = [ face ];
	
	# Create a surface per material
	for material in faces_by_material:
		surface_tool.clear();
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);
		surface_tool.set_material(material);
		
		var faces = faces_by_material[material];
		for i in range(faces.size()):
			var face: BrushFace = faces[i];
			
			var vertex_data := PoolVector3Array();
			var uv_data := PoolVector2Array();
			var color_data := PoolColorArray();
			var uv2_data := PoolVector2Array();
			var normal_data := PoolVector3Array();
			var tangent_data := Array();
			
			for j in range(face.vertices.size()):
				var vertex: BrushVertex = face.vertices[j];
				
				vertex_data.append(vertex.position);
				uv_data.append(vertex.uv);
				normal_data.append(vertex.normal);
				tangent_data.append(face.plane);
			
			surface_tool.add_triangle_fan(vertex_data, uv_data, color_data, uv2_data, normal_data, tangent_data);
		
		surface_tool.commit(visual_mesh);
	
	print_debug("Visual Mesh gen time: ", (OS.get_ticks_usec() - start_time) / 1000.0, "ms");
	
	return visual_mesh;


func build_collision_shape() -> Shape:
	var start_time := OS.get_ticks_usec();
	
	var collision_vertices := PoolVector3Array();
	for i in range(faces.size()):
		var face: BrushFace = faces[i];
		
		for j in range(face.vertices.size()):
			var vertex: BrushVertex = face.vertices[j];
			
			# Check for duplicate
			var unique_vertex := true;
			for other_vertex in collision_vertices:
				if other_vertex.is_equal_approx(vertex.position):
					unique_vertex = false;
					break;
			
			if unique_vertex:
				collision_vertices.append(vertex.position);
	
	var shape := ConvexPolygonShape.new();
	shape.points = collision_vertices;
	
	print_debug("Collision Shape gen time: ", (OS.get_ticks_usec() - start_time) / 1000.0, "ms");
	
	return shape;
