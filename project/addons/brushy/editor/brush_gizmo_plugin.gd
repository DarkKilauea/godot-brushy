extends EditorNode3DGizmoPlugin


var undo_redo: EditorUndoRedoManager;


func _init(undo: EditorUndoRedoManager) -> void:
	undo_redo = undo;
	
	create_material("border", Color.ORANGE);
	create_handle_material("face_centers");


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is Brush;


func _get_gizmo_name() -> String:
	return "Brush";


func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	return "Face %d distance" % handle_id;


func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	var brush := gizmo.get_node_3d() as Brush;
	if (!brush):
		return null;
	
	return brush.get_face_plane(handle_id);


func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var brush := gizmo.get_node_3d() as Brush;
	if (!brush):
		return;
	
	var brush_transform := brush.global_transform;
	var brush_inv_transform := brush_transform.affine_inverse();
	
	var ray_from := camera.project_ray_origin(screen_pos);
	var ray_dir := camera.project_ray_normal(screen_pos);
	
	ray_from = brush_inv_transform * ray_from;
	var ray_to = brush_inv_transform * (ray_from + ray_dir * camera.far);
	
	var face_plane := brush.get_face_plane(handle_id);
	var origin := Vector3.ZERO;
	var origin_from := origin + -face_plane.normal * camera.far;
	var origin_to := origin + face_plane.normal * camera.far;
	var res_points := Geometry3D.get_closest_points_between_segments(origin_from, origin_to, ray_from, ray_to);
	var new_pos := res_points[0];
	var new_distance := new_pos.distance_to(origin);
	
	if (!Plane(face_plane.normal, 0).is_point_over(new_pos)):
		new_distance = -new_distance
	
	# TODO: Enable support for snapping.
	#if (spatial_editor.is_snap_enabled()):
	#	new_distance = stepify(new_distance, spatial_editor.get_translate_snap());
	
	brush.set_face_plane(handle_id, Plane(face_plane.normal, new_distance));


func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	var brush := gizmo.get_node_3d() as Brush;
	if (!brush):
		return;

	if (cancel):
		brush.set_face_plane(handle_id, restore);
		return;
	
	undo_redo.create_action("Update Face Distance");
	undo_redo.add_do_method(brush, "set_face_plane", handle_id, brush.get_face_plane(handle_id));
	undo_redo.add_undo_method(brush, "set_face_plane", handle_id, restore);
	undo_redo.commit_action();


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	var brush := gizmo.get_node_3d() as Brush;
	
	gizmo.clear();
	var centers := PackedVector3Array();
	
	for fi in brush.get_face_count():
		var lines := PackedVector3Array();
		centers.append(brush.get_face_center(fi));
		
		var vertex_positions := brush.get_face_vertex_positions(fi);
		if (!vertex_positions.is_empty()):
			lines.append_array(vertex_positions);
			#lines.append(vertex_positions[0]);
		
		gizmo.add_lines(lines, get_material("border", gizmo));
		gizmo.add_collision_segments(lines);
	
	gizmo.add_handles(centers, get_material("face_centers", gizmo), []);
