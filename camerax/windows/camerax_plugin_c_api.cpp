#include "include/camerax/camerax_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "camerax_plugin.h"

void CameraxPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  camerax::CameraxPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
