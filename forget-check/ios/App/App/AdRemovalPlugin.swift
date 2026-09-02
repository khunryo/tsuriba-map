import Capacitor
import StoreKit

@objc(AdRemovalPlugin)
public class AdRemovalPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "AdRemovalPlugin"
    public let jsName = "AdRemoval"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getProduct", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchase", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restore", returnType: CAPPluginReturnPromise)
    ]

    private let productID = "jp.khunryo.forgetcheck.removeads"

    @objc public func getProduct(_ call: CAPPluginCall) {
        Task {
            do {
                guard let product = try await loadProduct() else {
                    call.resolve([
                        "available": false,
                        "purchased": await hasActiveEntitlement()
                    ])
                    return
                }

                call.resolve([
                    "available": true,
                    "id": product.id,
                    "displayName": product.displayName,
                    "displayPrice": product.displayPrice,
                    "purchased": await hasActiveEntitlement()
                ])
            } catch {
                call.reject("The ad-removal product could not be loaded.")
            }
        }
    }

    @objc public func getStatus(_ call: CAPPluginCall) {
        Task {
            call.resolve(["purchased": await hasActiveEntitlement()])
        }
    }

    @objc public func purchase(_ call: CAPPluginCall) {
        Task {
            do {
                if await hasActiveEntitlement() {
                    call.resolve(["status": "alreadyPurchased", "purchased": true])
                    return
                }

                guard let product = try await loadProduct() else {
                    call.resolve(["status": "unavailable", "purchased": false])
                    return
                }

                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    let transaction = try verified(verification)
                    guard transaction.productID == productID else {
                        call.reject("The purchase did not match the requested product.")
                        return
                    }
                    await transaction.finish()
                    call.resolve(["status": "purchased", "purchased": true])
                case .userCancelled:
                    call.resolve(["status": "cancelled", "purchased": false])
                case .pending:
                    call.resolve(["status": "pending", "purchased": false])
                @unknown default:
                    call.resolve(["status": "unknown", "purchased": false])
                }
            } catch {
                call.reject("The purchase could not be completed.")
            }
        }
    }

    @objc public func restore(_ call: CAPPluginCall) {
        Task {
            do {
                try await AppStore.sync()
                let purchased = await hasActiveEntitlement()
                call.resolve([
                    "status": purchased ? "restored" : "notFound",
                    "purchased": purchased
                ])
            } catch {
                call.reject("The purchase history could not be restored.")
            }
        }
    }

    private func loadProduct() async throws -> Product? {
        let products = try await Product.products(for: [productID])
        return products.first
    }

    private func hasActiveEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productID && transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw AdRemovalError.failedVerification
        }
    }
}

private enum AdRemovalError: Error {
    case failedVerification
}
