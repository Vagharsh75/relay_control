import Foundation
import MessageUI
import Flutter

class SmsHandler: NSObject, MFMessageComposeViewControllerDelegate {
    private var pendingResult: FlutterResult?

    func sendSms(phoneNumber: String, message: String, result: @escaping FlutterResult) {
        guard MFMessageComposeViewController.canSendText() else {
            result(FlutterError(code: "NOT_AVAILABLE", message: "SMS not available on this device", details: nil))
            return
        }

        pendingResult = result

        let controller = MFMessageComposeViewController()
        controller.recipients = [phoneNumber]
        controller.body = message
        controller.messageComposeDelegate = self

        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Cannot present SMS compose view", details: nil))
            pendingResult = nil
            return
        }

        rootViewController.present(controller, animated: true, completion: nil)
    }

    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true) { [weak self] in
            switch result {
            case .sent:
                self?.pendingResult?(true)
            case .cancelled:
                self?.pendingResult?(false)
            case .failed:
                self?.pendingResult?(FlutterError(code: "SEND_FAILED", message: "Message sending failed", details: nil))
            @unknown default:
                self?.pendingResult?(false)
            }
            self?.pendingResult = nil
        }
    }
}
