// Resolve the CGWindowID of a running application's window.

import AppKit
import CoreGraphics
import Foundation

struct Window {
    let id: CGWindowID
    let pid: pid_t
    let owner: String
    let name: String
    let bounds: CGRect
    let onScreen: Bool
    let layer: Int
}

func windows(ownedBy owner: String) -> ([Window], Bool) {
    let options: CGWindowListOption = [.optionAll]
    guard let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    else {
        return ([], false)
    }

    let titlesAvailable = raw.contains { entry in
        (entry[kCGWindowOwnerName as String] as? String) == owner
            && entry[kCGWindowName as String] != nil
    }
    let result: [Window] = raw.compactMap { entry -> Window? in
        guard
            let id = entry[kCGWindowNumber as String] as? CGWindowID,
            let ownerPID = entry[kCGWindowOwnerPID as String] as? Int,
            let ownerName = entry[kCGWindowOwnerName as String] as? String,
            ownerName == owner
        else { return nil }

        let name = entry[kCGWindowName as String] as? String ?? ""
        let layer = entry[kCGWindowLayer as String] as? Int ?? 0
        let onScreen = (entry[kCGWindowIsOnscreen as String] as? Bool) ?? false
        var bounds = CGRect.zero
        if let dictionary = entry[kCGWindowBounds as String] as? NSDictionary {
            bounds = CGRect(dictionaryRepresentation: dictionary) ?? .zero
        }
        return Window(
            id: id,
            pid: pid_t(ownerPID),
            owner: ownerName,
            name: name,
            bounds: bounds,
            onScreen: onScreen,
            layer: layer
        )
    }
    return (result, titlesAvailable)
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    FileHandle.standardError.write(
        Data("usage: window-id <ownerName> [windowName|--list] [--json]\n".utf8)
    )
    exit(2)
}

let owner = arguments[1]
let jsonMode = arguments.contains("--json")
let filter = arguments.dropFirst(2).first { $0 != "--json" }
let includesPanels = ProcessInfo.processInfo.environment["WINDOW_LAYER_MODE"] == "all"
let (owned, titlesAvailable) = windows(ownedBy: owner)
let candidates = owned.filter {
    (includesPanels || $0.layer == 0) && $0.bounds.width >= 64 && $0.bounds.height >= 64
}
.sorted {
    if $0.onScreen != $1.onScreen { return $0.onScreen && !$1.onScreen }
    let leftArea = $0.bounds.width * $0.bounds.height
    let rightArea = $1.bounds.width * $1.bounds.height
    if leftArea != rightArea { return leftArea > rightArea }
    return $0.id < $1.id
}

if filter == "--list" {
    for window in candidates {
        let flag = window.onScreen ? "onscreen" : "offscreen"
        let size = "\(Int(window.bounds.width))x\(Int(window.bounds.height))"
        print(
            "id=\(window.id) name=\"\(window.name)\" layer=\(window.layer) \(size) \(flag)"
        )
    }
    exit(candidates.isEmpty ? 1 : 0)
}

if !owned.isEmpty && !titlesAvailable {
    FileHandle.standardError.write(
        Data("window titles unavailable — Screen Recording permission likely missing\n".utf8)
    )
    exit(3)
}

let matches = filter.map { wanted in candidates.filter { $0.name == wanted } } ?? candidates
guard let window = matches.first else {
    FileHandle.standardError.write(Data("no window found for owner \(owner)\n".utf8))
    exit(1)
}

if matches.count > 1 {
    let alternatives = matches.map { "\($0.id):\($0.name)" }.joined(separator: ", ")
    FileHandle.standardError.write(
        Data("multiple windows matched [\(alternatives)]; pass a title to disambiguate\n".utf8)
    )
}

if jsonMode {
    let active = NSWorkspace.shared.frontmostApplication?.processIdentifier == window.pid
    let activationState = active ? "active" : "inactive"
    let keyState: String
    if window.layer == 0 {
        keyState = active ? "key" : "non-key"
    } else {
        keyState = "not-applicable-transient"
    }
    let object: [String: Any] = [
        "windowID": Int(window.id),
        "ownerPID": Int(window.pid),
        "owner": window.owner,
        "windowTitle": window.name,
        "windowLayer": window.layer,
        "frameSize": ["width": window.bounds.width, "height": window.bounds.height],
        "contentSize": NSNull(),
        "contentSizeNote": "CGWindow exposes frame bounds; content size requires app geometry",
        "onScreen": window.onScreen,
        "applicationActivationState": activationState,
        "keyStatus": keyState,
    ]
    let data = try JSONSerialization.data(
        withJSONObject: object,
        options: [.prettyPrinted, .sortedKeys]
    )
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
} else {
    print(window.id)
}
