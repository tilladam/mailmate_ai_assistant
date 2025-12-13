import SwiftUI
import AppKit

class ThinkingPanelController {
    static let shared = ThinkingPanelController()
    private var panel: NSPanel?

    func show() {
        DispatchQueue.main.async {
            if self.panel == nil {
                let panel = NSPanel(
                    contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
                    styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                    backing: .buffered,
                    defer: false
                )
                panel.isFloatingPanel = true
                panel.level = .floating
                panel.titlebarAppearsTransparent = true
                panel.titleVisibility = .hidden
                panel.backgroundColor = .clear
                panel.isOpaque = false
                panel.hasShadow = true
                panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

                let hostingView = NSHostingView(rootView: ThinkingView())
                panel.contentView = hostingView

                // Position near top-right of screen
                if let screen = NSScreen.main {
                    let screenFrame = screen.visibleFrame
                    let x = screenFrame.maxX - 220
                    let y = screenFrame.maxY - 80
                    panel.setFrameOrigin(NSPoint(x: x, y: y))
                }

                self.panel = panel
            }
            self.panel?.orderFront(nil)
        }
    }

    func hide() {
        DispatchQueue.main.async {
            self.panel?.orderOut(nil)
        }
    }
}

struct ThinkingView: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var dots: String {
        String(repeating: ".", count: dotCount + 1)
    }

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Thinking\(dots)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 80, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}
