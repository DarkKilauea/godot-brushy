extends EditorSpatialGizmoPlugin


var undo_redo: UndoRedo;


func _init(undo: UndoRedo) -> void:
	undo_redo = undo;
	
	create_material("border", Color.orange);
	create_handle_material("face_centers");


func has_gizmo(spatial) -> bool:
	return spatial is Brush;


func get_name() -> String:
	return "Brush";


func get_handle_name(gizmo: EditorSpatialGizmo, index: int) -> String:
	return "Face %d distance" % index;


func get_handle_value(gizmo: EditorSpatialGizmo, index: int):
	var brush := gizmo.get_spatial_node() as Brush;
	if (!brush):
		return null;
	
	return brush.get_face_plane(index);


func set_handle(gizmo: EditorSpatialGizmo, index: int, camera: Camera, point: Vector2) -> void:
	var brush := gizmo.get_spatial_node() as Brush;
	if (!brush):
		return;
	
	var brush_transform := brush.global_transform;
	var brush_inv_transform := brush_transform.affine_inverse();
	
	var ray_from := camera.project_ray_origin(point);
	var ray_dir := camera.project_ray_normal(point);
	
	ray_from = brush_inv_transform.xform(ray_from);
	var ray_to = brush_inv_transform.xform(ray_from + ray_dir * camera.far);
	
	var face_plane := brush.get_face_plane(index);
	var origin := Vector3.ZERO;
	var origin_from := origin + -face_plane.normal * camera.far;
	var origin_to := origin + face_plane.normal * camera.far;
	var res_points := Geometry.get_closest_points_between_segments(origin_from, origin_to, ray_from, ray_to);
	var new_pos := res_points[0];
	var new_distance := new_pos.distance_to(origin);
	
	if (!Plane(face_plane.normal, 0).is_point_over(new_pos)):
		new_distance = -new_distance
	
	# TODO: Enable support for snapping.
	#if (spatial_editor.is_snap_enabled()):
	#	new_distance = stepify(new_distance, spatial_editor.get_translate_snap());
	
	brush.set_face_plane(index, Plane(face_plane.normal, new_distance));


func commit_handle(gizmo: EditorSpatialGizmo, index: int, restore, cancel: bool = false) -> void:
	var brush := gizmo.get_spatial_node() as Brush;
	if (!brush):
		return;

	if (cancel):
		brush.set_face_plane(index, restore);
		return;
	
	undo_redo.create_action("Update Face Distance");
	undo_redo.add_do_method(brush, "set_face_plane", index, brush.get_face_plane(index));
	undo_redo.add_undo_method(brush, "set_face_plane", index, restore);
	undo_redo.commit_action();


func redraw(gizmo: EditorSpatialGizmo) -> void:
	var brush := gizmo.get_spatial_node() as Brush;
	
	gizmo.clear();
	var centers := PoolVector3Array();
	
	for fi in brush.faces.size():
		var lines := PoolVector3Array();
		var face: BrushFace = brush.faces[fi];
		centers.append(face.center);
		
		for vi in face.vertices.size():
			var vertex: BrushVertex = face.vertices[vi];
			lines.append(vertex.position);
		
		lines.append(face.vertices[0].position);
		
		gizmo.add_lines(lines, get_material("border", gizmo));
		gizmo.add_collision_segments(lines);
	
	gizmo.add_handles(centers, get_material("face_centers", gizmo));
