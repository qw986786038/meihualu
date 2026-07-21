// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "camerax",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .library(name: "camerax", targets: ["camerax"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "camerax",
      dependencies: [],
      resources: [
        .process("PrivacyInfo.xcprivacy")
      ]
    )
  ]
)
