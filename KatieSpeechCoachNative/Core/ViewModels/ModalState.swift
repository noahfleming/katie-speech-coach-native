import Foundation
import Combine

/// KAT-206: Modal / sheet presentation state extracted from AppViewModel.
///
/// Owns the two reactive flags that drive sheet presentation:
/// `isPremiumPreviewPresented` and `isReviewPresented`. These are read by
/// every feature view as the gating condition for showing overlays, so
/// grouping them on a small focused VM keeps the call sites obvious and
/// the sheet stack navigable from one place.
final class ModalState: ObservableObject, Codable {
    @Published var isPremiumPreviewPresented: Bool
    @Published var isReviewPresented: Bool

    init(
        isPremiumPreviewPresented: Bool = false,
        isReviewPresented: Bool = false
    ) {
        self.isPremiumPreviewPresented = isPremiumPreviewPresented
        self.isReviewPresented = isReviewPresented
    }

    private enum CodingKeys: String, CodingKey {
        case isPremiumPreviewPresented
        case isReviewPresented
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isPremiumPreviewPresented = try container.decodeIfPresent(Bool.self, forKey: .isPremiumPreviewPresented) ?? false
        isReviewPresented = try container.decodeIfPresent(Bool.self, forKey: .isReviewPresented) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isPremiumPreviewPresented, forKey: .isPremiumPreviewPresented)
        try container.encode(isReviewPresented, forKey: .isReviewPresented)
    }
}
