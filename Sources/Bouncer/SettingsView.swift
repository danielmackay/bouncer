import BouncerCore
import SwiftUI

struct SettingsView: View {
    @Bindable var preferences: Preferences
    let launchAtLogin: LaunchAtLogin

    var body: some View {
        Form {
            Picker("Auto-collapse after", selection: $preferences.autoCollapseTimeout) {
                ForEach(AutoCollapseTimeout.choices, id: \.self) { choice in
                    Text(Self.title(for: choice)).tag(choice)
                }
            }

            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))

            if launchAtLogin.needsApproval {
                HStack {
                    Text("Allow Bouncer in Login Items to finish turning this on.")
                        .foregroundStyle(.secondary)
                    Button("Open Login Items…") { launchAtLogin.openLoginItemsSettings() }
                }
                .font(.callout)
            }

            if let error = launchAtLogin.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }

    private static func title(for timeout: AutoCollapseTimeout) -> String {
        switch timeout {
        case .off: "Off"
        case .after(let duration): "\(duration.components.seconds) seconds"
        }
    }
}
