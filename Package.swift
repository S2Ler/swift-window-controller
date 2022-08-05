// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "swift-window-controller",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "WindowController",
      targets: ["WindowController"]
    ),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "WindowController",
      dependencies: []
    )
  ]
)
