extends EditorProperty


# The main control for editing the property.
var property_control := TextureRect.new();
# An internal value of the property.
var current_value = null;
# A guard against internal changes when the property is updated.
var updating := false;


func _init():
	property_control.expand = true;
	property_control.rect_min_size = Vector2(64, 64);

	# Add the control as a direct child of EditorProperty node.
	add_child(property_control);
	# Make sure the control is able to retain the focus.
	add_focusable(property_control);
	# Make sure the control appears under the label.
	set_bottom_editor(property_control);


func update_property():
	# Read the current value from the property.
	var new_value: Transform2D = get_edited_object()[get_edited_property()];
	if (new_value == current_value):
		return;
	
	var brush: Brush = get_edited_object();
	var prop_path := get_edited_property();
	var mat_path := prop_path.replace("uv_transform", "material");
	
	var texture: Texture = null;
	var material := brush[mat_path] as SpatialMaterial;
	if material:
		texture = material.albedo_texture;
	
	# Update the control with the new value.
	updating = true
	current_value = new_value
	property_control.texture = texture;
	updating = false
