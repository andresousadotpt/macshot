import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("General") {
                Toggle("Start Macshot at login", isOn: $viewModel.settings.launchAtLogin)
                    .onChange(of: viewModel.settings.launchAtLogin) { _, enabled in
                        Task { await viewModel.setLaunchAtLogin(enabled) }
                    }
            }

            Section("Hotkeys") {
                hotkeyRow(
                    title: "Screenshot",
                    description: viewModel.screenshotHotkeyDescription,
                    isRecording: viewModel.recordingTarget == .screenshot
                ) {
                    viewModel.startRecording(.screenshot)
                }

                hotkeyRow(
                    title: "Record GIF",
                    description: viewModel.gifHotkeyDescription,
                    isRecording: viewModel.recordingTarget == .gif
                ) {
                    viewModel.startRecording(.gif)
                }

                Text("Click a hotkey field, then press the desired key combination. Press Esc to cancel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("While Macshot is running, configured hotkeys replace the matching macOS screenshot shortcuts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Screenshot") {
                Slider(value: $viewModel.settings.dimOpacity, in: 0.1...0.7) {
                    Text("Overlay dim")
                }
                Text("Dim intensity: \(Int(viewModel.settings.dimOpacity * 100))%")
                    .foregroundStyle(.secondary)
            }

            Section("GIF Recording") {
                Stepper("FPS: \(viewModel.settings.gifFPS)", value: $viewModel.settings.gifFPS, in: 5...30)
                Stepper(
                    "Max duration: \(Int(viewModel.settings.maxRecordingDuration))s",
                    value: $viewModel.settings.maxRecordingDuration,
                    in: 5...60,
                    step: 5
                )
            }

            Section("Permissions") {
                Button("Request All Permissions") {
                    Task { await viewModel.requestAllPermissions() }
                }

                HStack {
                    Text("Accessibility")
                    Spacer()
                    Image(systemName: viewModel.accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(viewModel.accessibilityGranted ? .green : .orange)
                }
                Button("Request Accessibility") {
                    viewModel.requestAccessibilityPermission()
                }
                Button("Open Accessibility Settings") {
                    viewModel.openAccessibilitySettings()
                }

                HStack {
                    Text("Screen Recording")
                    Spacer()
                    Image(systemName: viewModel.screenRecordingGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(viewModel.screenRecordingGranted ? .green : .orange)
                }
                Button("Request Screen Recording") {
                    Task { await viewModel.requestScreenRecordingPermission() }
                }
                Button("Open Screen Recording Settings") {
                    viewModel.openScreenRecordingSettings()
                }

                HStack {
                    Text("Notifications")
                    Spacer()
                    Image(systemName: viewModel.notificationsGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(viewModel.notificationsGranted ? .green : .orange)
                }
                Button("Request Notifications") {
                    Task { await viewModel.requestNotificationPermission() }
                }
                Button("Open Notification Settings") {
                    viewModel.openNotificationSettings()
                }
            }

            if let saveMessage = viewModel.saveMessage {
                Text(saveMessage)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 460, minHeight: 520)
        .padding()
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.settings.dimOpacity) { _, _ in
            Task { await viewModel.save() }
        }
        .onChange(of: viewModel.settings.gifFPS) { _, _ in
            Task { await viewModel.save() }
        }
        .onChange(of: viewModel.settings.maxRecordingDuration) { _, _ in
            Task { await viewModel.save() }
        }
        .onDisappear {
            viewModel.cancelRecording()
        }
    }

    @ViewBuilder
    private func hotkeyRow(
        title: String,
        description: String,
        isRecording: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button {
                onTap()
            } label: {
                Text(isRecording ? "Press keys…" : description)
                    .font(.system(.body, design: .monospaced))
                    .frame(minWidth: 100)
            }
            .buttonStyle(.bordered)
            .tint(isRecording ? .accentColor : .secondary)
        }
    }
}
