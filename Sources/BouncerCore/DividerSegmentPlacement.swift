/// Which Divider segments sit where widening them hides the Hidden Section. The segments
/// are invisible, so a ⌘-drag of a neighbouring item can knock one out of place; widening
/// a segment among the Shown Section would push the Toggle and the Shown Section into the
/// System Overflow instead.
struct DividerSegmentPlacement: Sendable, Equatable {
    /// Segment indexes, in creation order, known to be out of place. Empty until a reading
    /// arrives: on first launch macOS lines the segments up next to the Divider.
    private(set) var misplaced: Set<Int> = []

    /// The widest step between neighbours that still counts as one unbroken run. macOS 27
    /// lays zero-length segments out 16pt apart, starting 16pt left of the Divider. Any
    /// Menu Bar Item between two of them adds at least its own icon width (16pt or more),
    /// making the step 32pt or more; 24pt sits halfway, absorbing rounding on either side.
    static let maxRunStep: Double = 24

    /// Replaces the placement with what a reading shows. `segmentXs` holds each segment's
    /// left edge in creation order, on the same display as `dividerX`, the Divider's left edge.
    /// In place means part of the unbroken run going left from the Divider; a segment right
    /// of the Divider, or beyond a gap, is out of place.
    mutating func observe(dividerX: Double, segmentXs: [Double]) {
        let nearestFirst = segmentXs.indices
            .filter { segmentXs[$0].isFinite && segmentXs[$0] < dividerX }
            .sorted { segmentXs[$0] > segmentXs[$1] }
        var inRun: Set<Int> = []
        var runEdge = dividerX
        for index in nearestFirst {
            guard runEdge - segmentXs[index] <= Self.maxRunStep else { break }
            inRun.insert(index)
            runEdge = segmentXs[index]
        }
        misplaced = Set(segmentXs.indices).subtracting(inRun)
    }

    func isInPlace(_ index: Int) -> Bool { !misplaced.contains(index) }
}
