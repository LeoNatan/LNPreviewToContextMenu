// swift-tools-version:5.1

import PackageDescription

let package = Package(
	name: "LNPreviewToContextMenu",
	platforms: [
		.iOS(.v11)
	],
	products: [
		.library(
			name: "LNPreviewToContextMenu",
			type: .dynamic,
			targets: ["LNPreviewToContextMenu"]),
		.library(
			name: "LNPreviewToContextMenu-Static",
			type: .static,
			targets: ["LNPreviewToContextMenu"]),
	],
	dependencies: [],
	targets: [
		.target(
			name: "LNPreviewToContextMenu",
			dependencies: [],
			path: "LNPreviewToContextMenu",
			exclude: [
				"LNPreviewToContextMenu/Info.plist",
				"LNPreviewToContextMenu.xcodeproj"
			],
			publicHeadersPath: "include",
			cSettings: [
				.headerSearchPath("."),
			]),
	]
)
