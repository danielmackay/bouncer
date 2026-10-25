/// How the Auto-collapse timeout is kept in user defaults: whole seconds, with 0 for Off.
/// The core owns the mapping so the app only reads and writes a plain integer.
extension AutoCollapseTimeout {
    /// The timeouts offered in Settings, in display order.
    public static let choices: [AutoCollapseTimeout] = [.off] + [5, 10, 30, 60].map { .after(.seconds($0)) }

    /// Anything other than one of `choices` (nothing stored yet, or a value edited by hand
    /// with `defaults write`) reads as the default, so Settings always has an option selected.
    public init(storedSeconds: Int?) {
        let stored: AutoCollapseTimeout? = switch storedSeconds {
        case nil: nil
        case 0: .off
        case let seconds?: .after(.seconds(seconds))
        }
        if let stored, Self.choices.contains(stored) {
            self = stored
        } else {
            self = .default
        }
    }

    /// The value to write to user defaults. A non-positive duration already behaves as
    /// Off, so it is stored as Off.
    public var storedSeconds: Int {
        guard let interval else { return 0 }
        return Int(interval.components.seconds)
    }
}
