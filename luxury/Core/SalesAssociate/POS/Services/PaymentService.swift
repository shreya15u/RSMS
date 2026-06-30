import Foundation
import UIKit
import Supabase
#if canImport(Razorpay)
import Razorpay
#endif

enum PaymentError: Error {
    case initializationFailed
    case paymentFailed(String)
    case cancelled
    case databaseError(String)
}

struct TransactionPayload: Encodable {
    let transaction_amount: Double
    let purpose: String
}

class PaymentService: NSObject {
    static let shared = PaymentService()
    
    #if canImport(Razorpay)
    private var razorpay: RazorpayCheckout?
    #endif
    
    private var currentContinuation: CheckedContinuation<String, Error>?
    private var pendingAmount: Double = 0.0
    
    override private init() {
        super.init()
    }
    
    @MainActor
    func processPayment(amount: Double, description: String = "POS Checkout", presentingViewController: UIViewController) async throws -> String {
        #if canImport(Razorpay)
        let rzp = RazorpayCheckout.initWithKey(RazorpayConfig.apiKey, andDelegateWithData: self)
        self.razorpay = rzp
        self.pendingAmount = amount
        
        let amountInPaise = Int(amount * 100)
        
        let options: [String: Any] = [
            "name": "Luxury Platform",
            "description": description,
            "image": "https://your-logo-url.com/logo.png",
            "amount": amountInPaise,
            "currency": "INR",
            "theme": [
                "color": "#D4AF37" // AppColors.gold equivalent
            ]
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            self.currentContinuation = continuation
            rzp.open(options, displayController: presentingViewController)
        }
        #else
        // Fallback if SDK is not yet linked
        print("Razorpay SDK not found. Simulating payment success.")
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return "pay_dummy_simulated"
        #endif
    }
}

#if canImport(Razorpay)
extension PaymentService: RazorpayPaymentCompletionProtocolWithData {
    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        if let continuation = currentContinuation {
            if str.lowercased().contains("cancel") {
                continuation.resume(throwing: PaymentError.cancelled)
            } else {
                continuation.resume(throwing: PaymentError.paymentFailed(str))
            }
            currentContinuation = nil
        }
        razorpay = nil
    }
    
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {
        if let continuation = currentContinuation {
            continuation.resume(returning: payment_id)
            currentContinuation = nil
        }
        razorpay = nil
    }
}
#endif
