import Foundation
import Combine

/// KAT-206: Premium / StoreKit + UX-message state extracted from AppViewModel.
///
/// First slice owns the reactive premium flags:
/// - `premiumAccessState` (locked / preview / entitled) — controls the
///   cross-app experience lock
/// - `premiumStoreStatus` (idle / loading / error etc.) — drives store
///   affordances and spinners
/// - `premiumRestoreMessage` — the success/neutral/warning message shown
///   after a restore attempt
/// - `pocketCopyStatusLine` — the local JSON export status line
/// - `practiceReturnCue` — the in-app "come back to practice" cue
///
/// Premium lifecycle methods (`unlockPremiumPreview`, `unlockPremiumFlow`,
/// `purchasePremiumIfAvailable`, `restorePremiumPurchases`,
/// `refreshPremiumStore`, `clearPremiumRestoreMessage`,
/// `clearPocketCopyStatusLine`, `exportPocketCopyToShareSheet`,
/// `importPocketCopy`) intentionally stay on `AppViewModel` for the next
/// careful slice — they call into `PremiumStore` (a `final class`
/// `ObservableObject` already extracted to `Core/Services/PremiumStore.swift`),
/// handle async purchase / restore, and reach into `ScenarioState` for the
/// export payload. Splitting that surface is the next step. Moving the storage
/// first keeps the public API (`appViewModel.premiumAccessState`,
/// `appViewModel.pocketCopyStatusLine`, …) stable and the build green.
final class PremiumState: ObservableObject, Codable {
    @Published var premiumAccessState: PremiumAccessState
    @Published var premiumStoreStatus: PremiumStoreStatus
    @Published var premiumRestoreMessage: PremiumRestoreMessage?
    @Published var pocketCopyStatusLine: String?
    @Published var practiceReturnCue: PracticeReturnCue?

    init(
        premiumAccessState: PremiumAccessState = .locked,
        premiumStoreStatus: PremiumStoreStatus = .idle,
        premiumRestoreMessage: PremiumRestoreMessage? = nil,
        pocketCopyStatusLine: String? = nil,
        practiceReturnCue: PracticeReturnCue? = nil
    ) {
        self.premiumAccessState = premiumAccessState
        self.premiumStoreStatus = premiumStoreStatus
        self.premiumRestoreMessage = premiumRestoreMessage
        self.pocketCopyStatusLine = pocketCopyStatusLine
        self.practiceReturnCue = practiceReturnCue
    }

    private enum CodingKeys: String, CodingKey {
        case premiumAccessState
        case pocketCopyStatusLine
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        premiumAccessState = try container.decodeIfPresent(PremiumAccessState.self, forKey: .premiumAccessState) ?? .locked
        premiumStoreStatus = .idle
        premiumRestoreMessage = nil
        pocketCopyStatusLine = try container.decodeIfPresent(String.self, forKey: .pocketCopyStatusLine)
        practiceReturnCue = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(premiumAccessState, forKey: .premiumAccessState)
        try container.encodeIfPresent(pocketCopyStatusLine, forKey: .pocketCopyStatusLine)
    }

    // MARK: - Mutators (state-local)

    func clearPremiumRestoreMessage() {
        premiumRestoreMessage = nil
    }

    func clearPocketCopyStatusLine() {
        pocketCopyStatusLine = nil
    }

    /// Move the user from locked → preview (used by the in-app preview sheet
    /// and the onboarding free-trial affordance).
    func unlockPreview() {
        premiumAccessState = .preview
    }
}
