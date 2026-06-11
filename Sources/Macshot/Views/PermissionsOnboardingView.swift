import SwiftUI

struct PermissionsOnboardingView: View {
    enum Mode {
        case onboarding
        case settings
    }

    private struct PermissionItem: Identifiable {
        let id: String
        let title: String
        let detail: String
        let granted: Bool
        let request: () -> Void
        let openSettings: () -> Void
    }

    @Bindable var viewModel: SettingsViewModel
    let mode: Mode
    let onContinue: () -> Void

    @State private var currentStepIndex = 0

    var body: some View {
        Group {
            switch mode {
            case .onboarding:
                onboardingView
            case .settings:
                settingsView
            }
        }
        .padding(24)
        .frame(width: 480)
        .task {
            await viewModel.refreshPermissionStatus()
        }
    }

    private var onboardingView: some View {
        let items = permissionItems
        let currentItem = items[currentStepIndex]

        return VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Macshot needs a few permissions")
                    .font(.title2.bold())
                Text("We'll ask for these one at a time so you can grant each when you're ready.")
                    .foregroundStyle(.secondary)
            }

            Text("Step \(currentStepIndex + 1) of \(items.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            permissionRow(
                title: currentItem.title,
                detail: currentItem.detail,
                granted: currentItem.granted,
                request: currentItem.request,
                openSettings: currentItem.openSettings,
                emphasize: true
            )

            HStack {
                if currentStepIndex > 0 {
                    Button("Back") {
                        currentStepIndex -= 1
                    }
                }

                Spacer()

                Button("Skip for Now") {
                    advanceOrFinish(from: items)
                }

                Button(currentStepIndex == items.count - 1 ? "Finish" : "Next") {
                    advanceOrFinish(from: items)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .onAppear {
            syncStepIndex(with: items)
        }
    }

    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Macshot needs a few permissions")
                    .font(.title2.bold())
                Text("Grant these so hotkeys, GIF recording, and recording feedback work correctly.")
                    .foregroundStyle(.secondary)
            }

            ForEach(permissionItems) { item in
                permissionRow(
                    title: item.title,
                    detail: item.detail,
                    granted: item.granted,
                    request: item.request,
                    openSettings: item.openSettings,
                    emphasize: false
                )
            }

            HStack {
                Button("Request All") {
                    Task { await viewModel.requestAllPermissions() }
                }

                Spacer()

                Button("Done") {
                    onContinue()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var permissionItems: [PermissionItem] {
        [
            PermissionItem(
                id: "notifications",
                title: "Notifications",
                detail: "Show when a GIF was copied or if recording failed.",
                granted: viewModel.notificationsGranted,
                request: { Task { await viewModel.requestNotificationPermission() } },
                openSettings: { viewModel.openNotificationSettings() }
            ),
            PermissionItem(
                id: "accessibility",
                title: "Accessibility",
                detail: "Override ⌘⇧3 and ⌘⇧4 screenshot shortcuts.",
                granted: viewModel.accessibilityGranted,
                request: { viewModel.requestAccessibilityPermission() },
                openSettings: { viewModel.openAccessibilitySettings() }
            ),
            PermissionItem(
                id: "screenRecording",
                title: "Screen Recording",
                detail: "Capture live screen regions for GIF recording.",
                granted: viewModel.screenRecordingGranted,
                request: { Task { await viewModel.requestScreenRecordingPermission() } },
                openSettings: { viewModel.openScreenRecordingSettings() }
            ),
        ]
    }

    private func advanceOrFinish(from items: [PermissionItem]) {
        if currentStepIndex < items.count - 1 {
            currentStepIndex += 1
            Task { await viewModel.refreshPermissionStatus() }
        } else {
            Task {
                await viewModel.refreshPermissionStatus()
                await viewModel.markPermissionOnboardingCompleted()
                onContinue()
            }
        }
    }

    private func syncStepIndex(with items: [PermissionItem]) {
        guard mode == .onboarding else { return }
        if let firstMissing = items.firstIndex(where: { !$0.granted }) {
            currentStepIndex = firstMissing
        }
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        detail: String,
        granted: Bool,
        request: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        emphasize: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(granted ? .green : .orange)
                .font(emphasize ? .title : .title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(emphasize ? .title3.weight(.semibold) : .headline)
                Text(detail)
                    .font(emphasize ? .body : .caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Button("Allow") { request() }
                        .disabled(granted)
                    Button("Open Settings") { openSettings() }
                }
            }
        }
        .padding(emphasize ? 12 : 0)
        .background(emphasize ? Color.secondary.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
    }
}
