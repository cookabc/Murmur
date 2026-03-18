import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let panelController = PanelController()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        configureButton()
        configureMenu()
        observeRecordingState()
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Voice Input")
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configureMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Panel", action: #selector(openPanel), keyEquivalent: "")
        menu.addItem(withTitle: "Refresh Status", action: #selector(refreshSmokeStatus), keyEquivalent: "r")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Voice Input", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        statusItem.menu = nil
        statusItem.menu = menu
    }

    private func observeRecordingState() {
        panelController.viewModel.$recordingLine
            .receive(on: RunLoop.main)
            .sink { [weak self] line in
                self?.updateStatusIcon(isRecording: line == "Recording live")
            }
            .store(in: &cancellables)
    }

    private func updateStatusIcon(isRecording: Bool) {
        let symbolName = isRecording ? "record.circle.fill" : "waveform.circle.fill"
        let description = isRecording ? "Voice Input — Recording" : "Voice Input"
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
    }

    @objc
    private func handleStatusItemClick(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else {
            panelController.togglePanel(relativeTo: statusItem.button)
            return
        }

        switch event.type {
        case .rightMouseUp:
            statusItem.button?.performClick(nil)
        default:
            statusItem.menu = nil
            panelController.togglePanel(relativeTo: statusItem.button)
            configureMenu()
        }
    }

    @objc
    private func openPanel() {
        panelController.showPanel(relativeTo: statusItem.button)
    }

    @objc
    private func refreshSmokeStatus() {
        panelController.refreshRustStatus()
        showPanel(relativeTo: statusItem.button)
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }

    private func showPanel(relativeTo button: NSStatusBarButton?) {
        panelController.showPanel(relativeTo: button)
    }
}
