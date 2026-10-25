/// Which Divider segments sit where widening them hides the Hidden Section. The segments
/// are invisible, so a ⌘-drag of a neighbouring item can knock one out of place; widening
/// a segment among the Shown Section would push the Toggle and the Shown Section into the
/// System Overflow instead.
struct DividerSegmentPlacement: Sendable, Equatable {
    /// Segment indexes, in creation order, known to be out of place. Empty until a reading
    /// arrives: on first launch macOS lines the segments up next to the Divider.
    private(set) var misplaced: Set<Int> = []

    /// Replaces the placement with what a reading shows. `segmentXs` holds each segment's
    /// left edge in creation order, on the same display as `dividerX`, the Divider's left edge.
    mutating func observe(dividerX: Double, segmentXs: [Double]) {
        misplaced = Set(segmentXs.indices.filter { !(segmentXs[$0] < dividerX) })
    }

    func isInPlace(_ index: Int) -> Bool { !misplaced.contains(index) }
}
