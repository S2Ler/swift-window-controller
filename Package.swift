// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "SystemWindowController",
  platforms: [
    .iOS(.v10)
  ],
  products: [
    .library(
      name: "SystemWindowController",
      targets: ["SystemWindowController"]
    ),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "SystemWindowController",
      dependencies: []
    )
  ]
)
