extends EditorInspectorPlugin


const MaterialTransformProperty = preload("res://addons/brushy/editor/material_transform_property.gd");


func can_handle(object: Object) -> bool:
    if object is Brush:
        return true;
    
    return false;


func parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
    if type == TYPE_TRANSFORM2D:
        add_property_editor(path, MaterialTransformProperty.new());
        return false;
    
    return false;
