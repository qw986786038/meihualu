//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <camerax/camerax_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) camerax_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "CameraxPlugin");
  camerax_plugin_register_with_registrar(camerax_registrar);
}
