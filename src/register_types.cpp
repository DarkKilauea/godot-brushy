#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "brush.h"

#ifdef TOOLS_ENABLED
#include "editor/brush_gizmo_plugin.h"
#include "editor/brushy_editor_plugin.h"
#endif

using namespace godot;

void gdextension_initialize(ModuleInitializationLevel p_level) {
	if (p_level == MODULE_INITIALIZATION_LEVEL_SCENE) {
		ClassDB::register_class<Brush>();
		ClassDB::register_class<BoxBrush>();
		ClassDB::register_class<CylinderBrush>();
	}
#ifdef TOOLS_ENABLED
	else if (p_level == MODULE_INITIALIZATION_LEVEL_EDITOR) {
		ClassDB::register_class<BrushGizmoPlugin>();
		ClassDB::register_class<BrushyEditorPlugin>();
		EditorPlugins::add_by_type<BrushyEditorPlugin>();
	}
#endif
}

void gdextension_terminate(ModuleInitializationLevel p_level) {
#ifdef TOOLS_ENABLED
	if (p_level == MODULE_INITIALIZATION_LEVEL_EDITOR) {
		EditorPlugins::remove_by_type<BrushyEditorPlugin>();
	}
#endif
}

extern "C" {
GDExtensionBool GDE_EXPORT gdextension_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(gdextension_initialize);
	init_obj.register_terminator(gdextension_terminate);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
