//
//  Generated file. Do not edit.
//

// clang-format off

#ifndef GENERATED_PLUGIN_REGISTRANT_
#define GENERATED_PLUGIN_REGISTRANT_

#if __has_include(<flutter/plugin_registry.h>)
#include <flutter/plugin_registry.h>

// Registers Flutter plugins.
void RegisterPlugins(flutter::PluginRegistry* registry);
#else
// Registers Flutter plugins.
#ifdef __cplusplus
namespace flutter {
class PluginRegistry;
}  // namespace flutter
void RegisterPlugins(flutter::PluginRegistry* registry);
#else
void RegisterPlugins(void* registry);
#endif
#endif

#endif  // GENERATED_PLUGIN_REGISTRANT_
