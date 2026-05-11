//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import camerax
import gal
import geolocator_apple
import package_info_plus
import photo_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  CameraxPlugin.register(with: registry.registrar(forPlugin: "CameraxPlugin"))
  GalPlugin.register(with: registry.registrar(forPlugin: "GalPlugin"))
  GeolocatorPlugin.register(with: registry.registrar(forPlugin: "GeolocatorPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  PhotoManagerPlugin.register(with: registry.registrar(forPlugin: "PhotoManagerPlugin"))
}
