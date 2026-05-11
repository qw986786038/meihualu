#include "camerax_plugin.h"
#include "photo_process_win.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>
#include <sstream>
#include <string>

namespace camerax {

// static
void CameraxPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "camerax",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<CameraxPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

CameraxPlugin::CameraxPlugin() {}

CameraxPlugin::~CameraxPlugin() {}

void CameraxPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
    return;
  }
  if (method_call.method_name().compare("processCaptureImage") == 0) {
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("bad_args", "Expected map", flutter::EncodableValue());
      return;
    }
    auto get_string = [&](const char* key) -> std::optional<std::string> {
      auto it = args->find(flutter::EncodableValue(key));
      if (it == args->end()) {
        return std::nullopt;
      }
      const auto* s = std::get_if<std::string>(&it->second);
      if (!s) {
        return std::nullopt;
      }
      return *s;
    };
    std::optional<std::string> input = get_string("inputPath");
    std::optional<std::string> output = get_string("outputPath");
    if (!input || !output) {
      result->Error("bad_args", "inputPath/outputPath", flutter::EncodableValue());
      return;
    }
    double aspect = 0.0;
    auto ait = args->find(flutter::EncodableValue("aspectRatio"));
    if (ait != args->end()) {
      const auto& v = ait->second;
      if (const auto* d = std::get_if<double>(&v)) {
        aspect = *d;
      } else if (const auto* i32 = std::get_if<int32_t>(&v)) {
        aspect = static_cast<double>(*i32);
      } else if (const auto* i64 = std::get_if<int64_t>(&v)) {
        aspect = static_cast<double>(*i64);
      }
    }
    int quality = 95;
    auto qit = args->find(flutter::EncodableValue("quality"));
    if (qit != args->end()) {
      const auto& qv = qit->second;
      if (const auto* i32 = std::get_if<int32_t>(&qv)) {
        quality = static_cast<int>(*i32);
      } else if (const auto* i64 = std::get_if<int64_t>(&qv)) {
        quality = static_cast<int>(*i64);
      }
    }
    bool ok = ProcessCaptureImageWin(*input, *output, aspect, quality);
    result->Success(flutter::EncodableValue(ok));
    return;
  }
  result->NotImplemented();
}

}  // namespace camerax
