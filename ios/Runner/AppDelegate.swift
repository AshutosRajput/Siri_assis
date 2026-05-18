import Flutter
import UIKit
import AppIntents

// MARK: - 1. Intent Dispatcher (Method Channel Queue)
// This queues intents securely if Flutter hasn't fully booted up yet.
class IntentDispatcher {
    static let shared = IntentDispatcher()
    private var channel: FlutterMethodChannel?
    private var pendingIntent: [String: Any]?
    private var isFlutterReady = false
    
    func setChannel(_ channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    func setFlutterReady() {
        isFlutterReady = true
        if let pending = pendingIntent {
            sendToFlutter(pending)
            pendingIntent = nil
        }
    }
    
    func dispatch(action: String, data: [String: Any]) {
        let payload: [String: Any] = ["action": action, "data": data]
        if isFlutterReady {
            sendToFlutter(payload)
        } else {
            pendingIntent = payload
        }
    }
    
    private func sendToFlutter(_ payload: [String: Any]) {
        DispatchQueue.main.async {
            self.channel?.invokeMethod("onSiriIntent", arguments: payload)
        }
    }
}

// MARK: - 2. Entities (Parameterized Options)
@available(iOS 16.0, *)
enum VoucherType: String, AppEnum {
    case amazon = "Amazon"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Voucher Type"
    static var caseDisplayRepresentations: [VoucherType: DisplayRepresentation] = [
        .amazon: "Amazon Voucher"
    ]
}

// MARK: - 3. App Intents (Siri Actions)
@available(iOS 16.0, *)
struct RedeemVoucherIntent: AppIntent {
    static var title: LocalizedStringResource = "Redeem Voucher"
    static var description = IntentDescription("Redeem a specific voucher.")
    static var openAppWhenRun: Bool = true // Forces app to open
    
    @Parameter(title: "Voucher Type")
    var voucher: VoucherType

    @MainActor
    func perform() async throws -> some IntentResult {
        let typeString = voucher.rawValue
        
        // Dispatch payload to Flutter
        IntentDispatcher.shared.dispatch(action: "REDEEM_VOUCHER", data: ["type": typeString])
        
        // Siri speaks this aloud while the app opens
        return .result(dialog: IntentDialog(stringLiteral: "Voucher redeemed successfully and points deducted"))
    }
}

@available(iOS 16.0, *)
struct OpenAndRedeemIntent: AppIntent {
    static var title: LocalizedStringResource = "Open and Redeem"
    static var description = IntentDescription("Opens the app and redeems the default voucher.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // Fallback to Amazon for this specific phrase
        IntentDispatcher.shared.dispatch(action: "REDEEM_VOUCHER", data: ["type": "Amazon"])
        
        return .result(dialog: IntentDialog(stringLiteral: "Voucher redeemed successfully and points deducted"))
    }
}

// MARK: - 4. App Shortcuts (Registering Phrases with iOS)
@available(iOS 16.0, *)
struct DemoAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RedeemVoucherIntent(),
            phrases: [
                "Redeem \(\.$voucher) voucher from \(.applicationName)"
            ],
            shortTitle: "Redeem Voucher",
            systemImageName: "gift"
        )
        AppShortcut(
            intent: OpenAndRedeemIntent(),
            phrases: [
                "Open and redeem this from \(.applicationName)"
            ],
            shortTitle: "Open and Redeem",
            systemImageName: "gift.fill"
        )
    }
}

// MARK: - 5. AppDelegate Method Channel Setup
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    // Use registrar to get the binary messenger safely without relying on window?.rootViewController
    if let registrar = self.registrar(forPlugin: "SiriIntents") {
        let siriChannel = FlutterMethodChannel(name: "com.example.demo/siri_intents", binaryMessenger: registrar.messenger())
          
        IntentDispatcher.shared.setChannel(siriChannel)
          
        siriChannel.setMethodCallHandler { (call, result) in
            if call.method == "flutterIsReady" {
                IntentDispatcher.shared.setFlutterReady()
                result(true)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // Register Siri Shortcuts Automatically
    if #available(iOS 16.0, *) {
        DemoAppShortcuts.updateAppShortcutParameters()
    }
      
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
