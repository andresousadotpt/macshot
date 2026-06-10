import SwiftUI

struct PermissionsOnboardingView: View {
    @Bindable var viewModel: SettingsViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Macshot needs a few permissions")
                    .font(.title2.bold())
                Text("Grant these so hotkeys, GIF recording, and recording feedback work correctly.")
                    .foregroundStyle(.secondary)
            }

            permissionRow(
                title: "Accessibility",
                detail: "Override ⌘⇧3 and ⌘⇧4 screenshot shortcuts.",
                granted: viewModel.accessibilityGranted,
                request: { viewModel.requestAccessibilityPermission() },
                openSettings: { viewModel.openAccessibilitySettings() }
            )

            permissionRow(
                title: "Screen Recording",
                detail: "Capture live screen regions for GIF recording.",
                granted: viewModel.screenRecordingGranted,
                request: { Task { await viewModel.requestScreenRecordingPermission() } },
                openSettings: { viewModel.openScreenRecordingSettings() }
            )

            permissionRow(
                title: "Notifications",
                detail: "Show when a GIF was copied or if recording failed.",
                granted: viewModel.notificationsGranted,
                request: { Task { await viewModel.requestNotificationPermission() } },
                openSettings: { viewModel.openNotificationSettings() }
            )

            HStack {
                Button("Request All") {
                    Task { await viewModel.requestAllPermissions() }
                }
                .keyboardShortcut(.defaultAction)

                Spacer()

                Button("Continue") {
                    Task {
                        await viewModel.markPermissionOnboardingCompleted()
                        onContinue()
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 480)
        .task {
            await viewModel.refreshPermissionStatus()
        }
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        detail: String,
        granted: Bool,
        request: @escaping () -> Void,
        openSettings: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(granted ? .green : .orange)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Button("Request") { request() }
                        .disabled(granted)
                    Button("Open Settings") { openSettings() }
                }
            }
        }
    }
}
