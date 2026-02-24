import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let smsHandler = SmsHandler()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.example.lift_restart/sms",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "sendSms":
                guard let args = call.arguments as? [String: Any],
                      let phoneNumber = args["phoneNumber"] as? String,
                      let message = args["message"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Phone number and message are required", details: nil))
                    return
                }
                self?.smsHandler.sendSms(phoneNumber: phoneNumber, message: message, result: result)
            case "getAvailableSims":
                result([])  // iOS doesn't expose SIM selection
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
