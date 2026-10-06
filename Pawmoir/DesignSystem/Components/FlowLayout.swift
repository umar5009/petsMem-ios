import SwiftUI

/// Wrapping row for personality tags and breed chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let rows = arrange(maxWidth: width, subviews: subviews)
        let height = rows.last.map { $0.maxY } ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(maxWidth: bounds.width, subviews: subviews)
        for row in rows {
            for item in row.items {
                item.view.place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + item.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0
        var y: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                current.height = current.items.map(\.size.height).max() ?? 0
                rows.append(current)
                y += current.height + spacing
                x = 0
                current = Row()
            }
            current.items.append(Item(view: view, x: x, y: y, size: size))
            x += size.width + spacing
        }
        if !current.items.isEmpty {
            current.height = current.items.map(\.size.height).max() ?? 0
            rows.append(current)
        }
        return rows
    }

    private struct Item {
        var view: LayoutSubview
        var x: CGFloat
        var y: CGFloat
        var size: CGSize
    }

    private struct Row {
        var items: [Item] = []
        var height: CGFloat = 0
        var maxY: CGFloat {
            (items.map(\.y).max() ?? 0) + height
        }
    }
}
