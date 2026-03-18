import SwiftUI

struct ShellPanelView: View {
    @ObservedObject var viewModel: ShellViewModel

    private let panelBackground = Color(red: 0.08, green: 0.12, blue: 0.13)
    private let panelSurface = Color(red: 0.12, green: 0.18, blue: 0.18)
    private let panelSurfaceStrong = Color(red: 0.18, green: 0.24, blue: 0.23)
    private let panelText = Color(red: 0.95, green: 0.94, blue: 0.89)
    private let panelMuted = Color(red: 0.67, green: 0.73, blue: 0.70)
    private let panelAccent = Color(red: 0.90, green: 0.58, blue: 0.31)
    private let panelAccentSoft = Color(red: 0.31, green: 0.52, blue: 0.49)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [panelBackground, Color(red: 0.10, green: 0.16, blue: 0.17)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(panelAccent.opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 30)
                .offset(x: 130, y: -170)

            Circle()
                .fill(panelAccentSoft.opacity(0.22))
                .frame(width: 180, height: 180)
                .blur(radius: 24)
                .offset(x: -140, y: 170)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voice Input")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("A compact local dictation panel for the menu bar")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(panelMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        Text(viewModel.runtimeBadge)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(viewModel.runtimeBadge == "Ready" ? panelAccent.opacity(0.22) : Color.white.opacity(0.12), in: Capsule())
                        Text("Core \(viewModel.rustVersion)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(panelMuted)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(panelText)
                        .lineLimit(2)
                    Text(viewModel.detail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(panelMuted)
                        .lineSpacing(2)
                }
                .padding(16)
                .background(panelSurface.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(spacing: 10) {
                    statusRow(systemImage: "waveform", title: viewModel.ffmpegLine)
                    statusRow(systemImage: "text.bubble", title: viewModel.coliLine)
                    statusRow(systemImage: "mic", title: viewModel.recordingLine)
                }

                if !viewModel.recordingPath.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Latest clip")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(panelMuted)
                        Text(viewModel.recordingPath)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(panelText.opacity(0.9))
                            .lineLimit(3)
                    }
                    .padding(14)
                    .background(panelSurface.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if !viewModel.actionError.isEmpty {
                    Text(viewModel.actionError)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.78))
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.33, green: 0.15, blue: 0.13).opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if !viewModel.transcriptText.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Transcript")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(panelMuted)

                        Text(viewModel.transcriptText)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(panelText)
                            .textSelection(.enabled)

                        if !viewModel.transcriptMeta.isEmpty {
                            Text(viewModel.transcriptMeta)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(panelMuted)
                        }

                        HStack(spacing: 10) {
                            Button("Copy") {
                                viewModel.copyTranscript()
                            }
                            .buttonStyle(.bordered)
                            .tint(panelAccentSoft)

                            Button("Paste") {
                                viewModel.pasteTranscript()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(panelAccent)
                        }
                    }
                    .padding(16)
                    .background(panelSurfaceStrong.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        actionButton(title: "Record", systemImage: "mic.fill", prominent: true, tint: panelAccent) {
                            viewModel.startRecording()
                        }

                        actionButton(title: "Stop", systemImage: "stop.fill", tint: panelAccentSoft) {
                            viewModel.stopRecording()
                        }

                        actionButton(title: "Transcribe", systemImage: "text.bubble.fill", tint: panelAccentSoft) {
                            viewModel.transcribeLatestRecording()
                        }
                    }

                    HStack(spacing: 10) {
                        actionButton(title: "Refresh", systemImage: "arrow.clockwise", tint: panelAccentSoft) {
                            viewModel.refreshRuntime()
                        }

                        actionButton(title: "Project", systemImage: "folder", tint: panelAccentSoft) {
                            NSWorkspace.shared.open(URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
                        }
                    }
                }
            }
            .padding(18)
        }
        .frame(width: 408, height: 500)
        .foregroundStyle(panelText)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.refreshRuntime()
        }
    }

    @ViewBuilder
    private func statusRow(systemImage: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 18)
                .foregroundStyle(panelAccent)

            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(panelText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(panelSurface.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func actionButton(title: String, systemImage: String, prominent: Bool = false, tint: Color, action: @escaping () -> Void) -> some View {
        if prominent {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(tint)
        } else {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(tint)
        }
    }
}
