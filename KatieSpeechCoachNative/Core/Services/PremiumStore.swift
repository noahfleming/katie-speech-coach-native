import Foundation
import StoreKit

enum PremiumAccessState: String, Codable {
    case locked
    case preview
    case entitled

    var allowsPremiumExperience: Bool {
        self == .preview || self == .entitled
    }

    var title: String {
        switch self {
        case .locked: return "Katie Plus locked"
        case .preview: return "Katie Plus preview"
        case .entitled: return "Katie Plus active"
        }
    }
}

enum PremiumStoreStatus: Equatable {
    case idle
    case loadingProducts
    case ready(priceLabel: String)
    case purchasing
    case restoring
    case pendingApproval
    case unavailable(reason: String)
    case failed(message: String)
}

extension PremiumStoreStatus {
    var ctaTitle: String {
        switch self {
        case .idle, .loadingProducts:
            return "Checking availability…"
        case .ready(let priceLabel):
            return "Continue with Katie Plus · \(priceLabel)"
        case .purchasing:
            return "Purchasing Katie Plus…"
        case .restoring:
            return "Restoring Katie Plus…"
        case .pendingApproval:
            return "Purchase pending approval"
        case .unavailable:
            return "Keep preview mode"
        case .failed:
            return "Try Katie Plus again"
        }
    }

    var detailLine: String {
        switch self {
        case .idle:
            return "Checking with the App Store…"
        case .loadingProducts:
            return "Loading Katie Plus from the App Store…"
        case .ready(let priceLabel):
            return "Katie Plus is ready at \(priceLabel)."
        case .purchasing:
            return "Completing the App Store purchase now."
        case .restoring:
            return "Checking the App Store for an existing Katie Plus purchase."
        case .pendingApproval:
            return "The App Store accepted the request, but it's still pending."
        case .unavailable(let reason):
            return reason
        case .failed(let message):
            return message
        }
    }

    var isBusy: Bool {
        switch self {
        case .loadingProducts, .purchasing, .restoring:
            return true
        default:
            return false
        }
    }
}

enum PremiumRestoreOutcome: Equatable {
    case restored
    case noActiveSubscription
    case failed(message: String)
}

enum PremiumPurchaseOutcome: Equatable {
    case purchased
    case pendingApproval
    case userCancelled
    case fallbackPreview
}

@MainActor
final class PremiumStore: ObservableObject {
    static let shared = PremiumStore()

    let productIDs = ["com.noah.katiespeechcoach.plus.monthly"]

    @Published private(set) var status: PremiumStoreStatus = .idle
    @Published private(set) var product: Product?
    @Published private(set) var hasActiveEntitlement = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = observeTransactions()
    }

    deinit {
        updatesTask?.cancel()
    }

    func prepare() async {
        await refreshProductsIfNeeded(force: false)
        await refreshEntitlements()
    }

    func refreshProductsIfNeeded(force: Bool) async {
        if !force, product != nil { return }

        status = .loadingProducts
        do {
            let products = try await Product.products(for: productIDs)
            if let first = products.first {
                product = first
                status = .ready(priceLabel: first.displayPrice)
            } else {
                product = nil
                status = .unavailable(reason: "Katie Plus isn't available to buy just yet. You can keep exploring in preview mode.")
            }
        } catch {
            product = nil
            status = .failed(message: "We couldn't reach the App Store right now. Try again in a moment.")
        }
    }

    func purchase() async throws -> PremiumPurchaseOutcome {
        if product == nil {
            await refreshProductsIfNeeded(force: true)
        }

        guard let product else {
            return .fallbackPreview
        }

        status = .purchasing
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
            return .purchased
        case .pending:
            status = .pendingApproval
            return .pendingApproval
        case .userCancelled:
            await refreshProductsIfNeeded(force: false)
            return .userCancelled
        @unknown default:
            status = .failed(message: "Something went wrong with the purchase. Nothing was charged — please try again.")
            return .userCancelled
        }
    }

    func restorePurchases() async -> PremiumRestoreOutcome {
        status = .restoring
        do {
            try await AppStore.sync()
            await refreshProductsIfNeeded(force: product == nil)
            await refreshEntitlements()
            return hasActiveEntitlement ? .restored : .noActiveSubscription
        } catch {
            let message: String
            if let product {
                status = .ready(priceLabel: product.displayPrice)
                message = "We couldn't restore your purchases right now. Check your connection and try again."
            } else {
                status = .failed(message: "We couldn't restore your purchases right now. Check your connection and try again.")
                message = "We couldn't restore your purchases right now. Check your connection and try again."
            }
            return .failed(message: message)
        }
    }

    func refreshEntitlements() async {
        hasActiveEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if productIDs.contains(transaction.productID) {
                hasActiveEntitlement = true
                if let product {
                    status = .ready(priceLabel: product.displayPrice)
                } else {
                    status = .idle
                }
                return
            }
        }

        if let product {
            status = .ready(priceLabel: product.displayPrice)
        } else if case .loadingProducts = status {
            return
        } else if case .unavailable = status {
            return
        } else if case .failed = status {
            return
        } else {
            status = .idle
        }
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await update in Transaction.updates {
                guard let transaction = try? self.checkVerified(update) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signedType):
            return signedType
        case .unverified:
            throw StoreError.failedVerification
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
