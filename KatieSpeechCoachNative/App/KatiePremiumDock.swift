import SwiftUI

struct KatiePremiumDock<Leading: View, Trailing: View>: View {
    let title: String
    let message: String
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        message: String,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.message = message
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(KatieColors.textPrimary)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(KatieColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                leading()
                Spacer(minLength: 0)
                trailing()
            }
        }
        .padding(16)
        .background(KatieColors.cardBackground.opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(KatieColors.cardBorder.opacity(0.6), lineWidth: 1)
        )
    }
}
