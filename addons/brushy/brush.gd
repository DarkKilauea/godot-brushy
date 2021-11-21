tool
class_name Brush
extends Spatial


var mesh_instance := MeshInstance.new();
var vertices := PoolVector3Array();

var collision_parent: CollisionObject;
var collision_owner_id := -1;
var collision_enabled := true setget _set_collision_enabled;
var collision_shape: Shape setget _set_collision_shape;


func _init() -> void:
	#TODO: Init from tool, this is just for debugging
	var temp := CubeMesh.new();
	var data := temp.get_mesh_arrays();
	vertices = data[Mesh.ARRAY_VERTEX];
	print(vertices);
	
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
		},
		{
			"name": "vertices",
			"type": TYPE_VECTOR3_ARRAY,
			"usage": PROPERTY_USAGE_NOEDITOR
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
		
		NOTIFICATION_UNPARENTED:
			if (collision_parent):
				collision_parent.remove_shape_owner(collision_owner_id);
			
			collision_owner_id = -1;
			collision_parent = null;
		
		NOTIFICATION_ENTER_TREE:
			if (collision_parent):
				collision_parent.shape_owner_set_transform(collision_owner_id, transform);
				collision_parent.shape_owner_set_disabled(collision_owner_id, !collision_enabled);
		
		NOTIFICATION_TRANSFORM_CHANGED:
			if (collision_parent):
				collision_parent.shape_owner_set_transform(collision_owner_id, transform);


func _set_collision_enabled(value: bool) -> void:
	collision_enabled = value;
	update_gizmo();
	
	if (collision_parent):
		collision_parent.shape_owner_set_disabled(collision_owner_id, !collision_enabled);


func _set_collision_shape(value: Shape) -> void:
	if (collision_shape == value):
		return;
	
	collision_shape = value;
	update_gizmo();
	
	if (collision_parent):
		collision_parent.shape_owner_clear_shapes(collision_owner_id);
		if (collision_shape):
			collision_parent.shape_owner_add_shape(collision_owner_id, collision_shape);


func _update_meshes() -> void:
	mesh_instance.mesh = generate_visual_mesh();
	self.collision_shape = generate_physics_shape();


func generate_visual_mesh() -> Mesh:
	# TODO: Generate from vertex array
	var cube_mesh := CubeMesh.new();
	return cube_mesh;


func generate_physics_shape() -> Shape:
	var shape := ConvexPolygonShape.new();
	shape.points = vertices;
	return shape;


class BrushFace:
	var plane: Plane;
	var material: Material;
	var tex_transform: Transform2D;
