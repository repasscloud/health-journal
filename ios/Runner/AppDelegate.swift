import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "JournalPrivateStore")!
    let channel = FlutterMethodChannel(name: "health_journal/private_store",
      binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "prepare" else { result(FlutterMethodNotImplemented); return }
      do {
        let manager = FileManager.default
        var directory = try manager.url(for: .applicationSupportDirectory,
          in: .userDomainMask, appropriateFor: nil, create: true)
          .appendingPathComponent("ProtectedJournal", isDirectory: true)
        try manager.createDirectory(at: directory, withIntermediateDirectories: true,
          attributes: [.protectionKey: FileProtectionType.complete])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        // Reapply to existing files, including SQLite WAL/SHM/journal files.
        let children = try manager.contentsOfDirectory(at: directory,
          includingPropertiesForKeys: nil)
        for url in [directory] + children {
          try manager.setAttributes([.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path)
          var protectedURL = url
          try protectedURL.setResourceValues(values)
        }
        result(directory.path)
      } catch {
        result(FlutterError(code: "protected_storage_unavailable",
          message: "Protected storage could not be prepared.", details: nil))
      }
    }
  }
}
