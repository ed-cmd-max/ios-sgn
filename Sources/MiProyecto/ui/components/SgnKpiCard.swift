#if canImport(SwiftUI)
import SwiftUI

struct SgnKpiCard: View {
    let title: String
    let value: Int
    var tint: Color = SgnColor.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value.formatted()).font(.title2.weight(.bold)).foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
#endif