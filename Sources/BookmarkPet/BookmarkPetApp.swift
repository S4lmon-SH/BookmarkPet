import AppKit
import BookmarkPetCore
import ServiceManagement
import SwiftUI

@main
enum BookmarkPetMain {
    static func main() {
        let app = NSApplication.shared
        if ProcessInfo.processInfo.arguments.contains("--light-appearance") {
            app.appearance = NSAppearance(named: .aqua)
        }
        let delegate = BookmarkPetDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
private final class MemoViewModel: ObservableObject {
    @Published private(set) var text: String
    @Published private(set) var hasMemo: Bool
    @Published private(set) var canUndoClear = false
    @Published var errorMessage: String?
    var onBadgeChange: ((Bool) -> Void)?

    private let session: MemoSession

    init(store: (any MemoStore)? = nil) throws {
        let effectiveStore: any MemoStore
        if let store {
            effectiveStore = store
        } else {
            effectiveStore = try MemoFileStore.defaultStore()
        }
        session = try MemoSession(store: effectiveStore)
        text = session.text
        hasMemo = session.hasMemo
    }

    func replace(with value: String) {
        do {
            try session.replace(with: value)
            publish()
        } catch {
            errorMessage = "메모를 저장하지 못했습니다: \(error.localizedDescription)"
        }
    }

    func clear() {
        do {
            try session.clear()
            publish()
        } catch {
            errorMessage = "메모를 비우지 못했습니다: \(error.localizedDescription)"
        }
    }

    func undoClear() {
        do {
            try session.undoClear()
            publish()
        } catch {
            errorMessage = "메모를 복원하지 못했습니다: \(error.localizedDescription)"
        }
    }

    private func publish() {
        let oldBadge = hasMemo
        text = session.text
        hasMemo = session.hasMemo
        canUndoClear = session.undoText != nil
        errorMessage = nil
        if oldBadge != hasMemo { onBadgeChange?(hasMemo) }
    }
}

@MainActor
private final class LoginItemModel: ObservableObject {
    @Published private(set) var status = SMAppService.mainApp.status
    @Published var errorMessage: String?

    var isRegistered: Bool {
        status == .enabled || status == .requiresApproval
    }

    var statusMessage: String? {
        switch status {
        case .enabled: return "로그인 시 자동으로 실행됩니다."
        case .requiresApproval: return "시스템 설정에서 로그인 항목 승인이 필요합니다."
        case .notFound: return "로그인 항목 등록 정보가 없습니다. 켜면 등록을 시도합니다."
        case .notRegistered: return nil
        @unknown default: return "로그인 항목 상태를 확인할 수 없습니다."
        }
    }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = "로그인 항목을 변경하지 못했습니다: \(error.localizedDescription)"
        }
        refresh()
    }
}

@MainActor
private final class BookmarkPetDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var memo: MemoViewModel?
    private let loginItem = LoginItemModel()
    private weak var editor: NSTextView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainMenu()
        if ProcessInfo.processInfo.arguments.contains("--verify-login-item") {
            verifyLoginItemRegistration()
            NSApp.terminate(nil)
            return
        }
        do {
            let arguments = ProcessInfo.processInfo.arguments
            let smokeIndex = arguments.firstIndex(of: "--verify-ui")
            let smokeReport = smokeIndex.flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
            let memoFileIndex = arguments.firstIndex(of: "--memo-file")
            let memoFile = memoFileIndex.flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
                ?? smokeReport.map { $0 + ".memo" }
            let store = memoFile.map { MemoFileStore(fileURL: URL(fileURLWithPath: $0)) }
            let memo = try MemoViewModel(store: store)
            self.memo = memo
            memo.onBadgeChange = { [weak self] hasMemo in self?.updateIcon(hasMemo: hasMemo, animate: true) }
            configureStatusItem(hasMemo: memo.hasMemo)
            configurePopover(memo: memo)
            NSWorkspace.shared.notificationCenter.addObserver(
                self, selector: #selector(refreshAfterWake),
                name: NSWorkspace.didWakeNotification, object: nil
            )
            if ProcessInfo.processInfo.arguments.contains("--show-popover") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.togglePopover() }
            }
            if let smokeReport {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.runUISmokeTest(reportPath: smokeReport)
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "BookmarkPet을 열 수 없습니다"
            alert.informativeText = "저장된 메모를 읽지 못했습니다: \(error.localizedDescription)"
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    private func configureMainMenu() {
        // AppKit routes Command key equivalents through the main menu, even for
        // an accessory app whose menu bar is hidden during normal operation.
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "BookmarkPet")
        appMenu.addItem(withTitle: "BookmarkPet 종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "편집")
        editMenu.addItem(withTitle: "실행 취소", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "다시 실행", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "잘라내기", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "복사", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "붙여넣기", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "전체 선택", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)
        NSApp.mainMenu = mainMenu
    }

    private func runUISmokeTest(reportPath: String) {
        let output = URL(fileURLWithPath: reportPath)
        try? "UI smoke test started\n".write(to: output, atomically: true, encoding: .utf8)
        togglePopover()
        try? "popover show requested: \(popover.isShown)\n".write(to: output, atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            guard let editor = self.editor, let memo = self.memo else {
                try? "popover visible: \(self.popover.isShown)\neditor unavailable\n".write(to: output, atomically: true, encoding: .utf8)
                NSApp.terminate(nil)
                return
            }
            var checks = [String]()
            checks.append("popover visible: \(self.popover.isShown)")
            checks.append("editor focused: \(editor.window?.firstResponder === editor)")
            checks.append("empty badge: \(!memo.hasMemo)")
            checks.append("fixed status width: \(self.statusItem?.length == 29)")
            checks.append("template status icon: \(self.statusItem?.button?.image?.isTemplate == true)")
            let content = "  한글 메모\n두 번째 줄  "
            let pasteboard = NSPasteboard.general
            let previousItems = (pasteboard.pasteboardItems ?? []).map { item in
                let copy = NSPasteboardItem()
                for type in item.types {
                    if let data = item.data(forType: type) { copy.setData(data, forType: type) }
                }
                return copy
            }
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
            if let pasteEvent = NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: .command,
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: editor.window?.windowNumber ?? 0, context: nil,
                characters: "v", charactersIgnoringModifiers: "v", isARepeat: false, keyCode: 9
            ) {
                NSApp.sendEvent(pasteEvent)
            }
            pasteboard.clearContents()
            pasteboard.writeObjects(previousItems)
            checks.append("Command+V pastes and persists with badge: \(memo.text == content && memo.hasMemo && self.statusItem?.button?.toolTip == "BookmarkPet — 저장된 메모 있음")")
            self.popover.performClose(nil)
            self.togglePopover()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self else { return }
                checks.append("reopen restores text: \(self.editor?.string == content)")
                memo.clear()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    checks.append("clear updates editor and badge: \(self.editor?.string == "" && !memo.hasMemo && self.statusItem?.button?.toolTip == "BookmarkPet — 메모 없음")")
                    memo.undoClear()
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        checks.append("undo restores editor and badge: \(self.editor?.string == content && memo.hasMemo && self.statusItem?.button?.toolTip == "BookmarkPet — 저장된 메모 있음")")
                        let report = checks.joined(separator: "\n") + "\n"
                        try? report.write(to: output, atomically: true, encoding: .utf8)
                        self.popover.performClose(nil)
                        NSApp.terminate(nil)
                    }
                }
            }
        }
    }

    private func verifyLoginItemRegistration() {
        let service = SMAppService.mainApp
        let initialStatus = service.status
        var report = ["login item initial status: \(initialStatus)"]
        if initialStatus == .notRegistered || initialStatus == .notFound {
            do {
                try service.register()
                report.append("login item after register: \(service.status)")
                try service.unregister()
                report.append("login item after unregister: \(service.status)")
            } catch {
                report.append("login item verification error: \(error.localizedDescription)")
                if service.status != .notRegistered {
                    try? service.unregister()
                }
            }
        }
        let text = report.joined(separator: "\n") + "\n"
        print(text, terminator: "")
        if let index = ProcessInfo.processInfo.arguments.firstIndex(of: "--verify-login-item"),
           ProcessInfo.processInfo.arguments.indices.contains(index + 1) {
            let output = URL(fileURLWithPath: ProcessInfo.processInfo.arguments[index + 1])
            try? text.write(to: output, atomically: true, encoding: .utf8)
        }
    }

    private func configureStatusItem(hasMemo: Bool) {
        let item = NSStatusBar.system.statusItem(withLength: 29)
        item.button?.imagePosition = .imageOnly
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        statusItem = item
        updateIcon(hasMemo: hasMemo, animate: false)
    }

    private func configurePopover(memo: MemoViewModel) {
        popover.behavior = .transient
        popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        popover.delegate = self
        popover.contentSize = NSSize(width: 304, height: 174)
        let content = MemoPopoverView(
            memo: memo,
            loginItem: loginItem,
            onEditorReady: { [weak self] editor in self?.editor = editor },
            onEscape: { [weak self] in self?.closePopover() },
            onSettingsMenuFinished: { [weak self] selectedItem, location in
                self?.settingsMenuDidFinish(selectedItem: selectedItem, at: location)
            }
        )
        popover.contentViewController = NSHostingController(rootView: content)
        if ProcessInfo.processInfo.arguments.contains("--light-appearance") {
            popover.contentViewController?.view.appearance = NSAppearance(named: .aqua)
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            closePopover()
            return
        }
        loginItem.refresh()
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        if ProcessInfo.processInfo.arguments.contains("--light-appearance") {
            popover.contentViewController?.view.window?.appearance = NSAppearance(named: .aqua)
        }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.popover.isShown, let editor = self.editor else { return }
            self.popover.contentViewController?.view.window?.makeFirstResponder(editor)
        }
    }

    private func settingsMenuDidFinish(selectedItem: Bool, at screenLocation: NSPoint) {
        guard popover.isShown else { return }
        let insidePopover: Bool
        if let content = popover.contentViewController?.view, let window = content.window {
            // The window also includes transparent shadow and arrow margins.
            let contentRect = window.convertToScreen(content.convert(content.bounds, to: nil))
            insidePopover = contentRect.contains(screenLocation)
        } else {
            insidePopover = false
        }
        // Menu tracking consumes its outside click before NSPopover can see it.
        if !NSApp.isActive || (!selectedItem && !insidePopover) {
            closePopover()
        }
    }

    private func closePopover() {
        guard popover.isShown else { return }
        editor?.unmarkText()
        if let text = editor?.string { memo?.replace(with: text) }
        popover.performClose(nil)
    }

    func applicationDidResignActive(_ notification: Notification) {
        closePopover()
    }

    func popoverDidShow(_ notification: Notification) {
        recordPopoverState("open")
    }

    func popoverDidClose(_ notification: Notification) {
        // NSTextView saves every change; this also commits any marked IME text.
        editor?.unmarkText()
        if let text = editor?.string { memo?.replace(with: text) }
        recordPopoverState("closed")
    }

    private func recordPopoverState(_ state: String) {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--popover-state-file"),
              arguments.indices.contains(index + 1) else { return }
        try? (state + "\n").write(to: URL(fileURLWithPath: arguments[index + 1]), atomically: true, encoding: .utf8)
    }

    func applicationWillTerminate(_ notification: Notification) {
        editor?.unmarkText()
        if let text = editor?.string { memo?.replace(with: text) }
    }

    @objc private func refreshAfterWake() {
        loginItem.refresh()
        if let memo { updateIcon(hasMemo: memo.hasMemo, animate: false) }
    }

    private func updateIcon(hasMemo: Bool, animate: Bool) {
        guard let button = statusItem?.button else { return }
        button.image = BookmarkIcon.image(hasMemo: hasMemo)
        button.toolTip = hasMemo ? "BookmarkPet — 저장된 메모 있음" : "BookmarkPet — 메모 없음"
        button.setAccessibilityLabel(button.toolTip)
        if animate && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            button.alphaValue = 0.68
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                button.animator().alphaValue = 1
            }
        }
    }
}

private struct MemoPopoverView: View {
    @ObservedObject var memo: MemoViewModel
    @ObservedObject var loginItem: LoginItemModel
    let onEditorReady: (NSTextView) -> Void
    let onEscape: () -> Void
    let onSettingsMenuFinished: (Bool, NSPoint) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("돌아오면 무엇부터 할까요?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                MemoSettingsButton(memo: memo, loginItem: loginItem,
                                   onFinished: onSettingsMenuFinished)
                    .frame(width: 22, height: 22)
            }

            MemoEditor(
                text: memo.text,
                onChange: memo.replace(with:),
                onReady: onEditorReady,
                onEscape: onEscape
            )
            .frame(height: 112)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator.opacity(0.35)))

            if let message = memo.errorMessage {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(width: 304)
        .onAppear { loginItem.refresh() }
    }
}

private struct MemoSettingsButton: NSViewRepresentable {
    let memo: MemoViewModel
    let loginItem: LoginItemModel
    let onFinished: (Bool, NSPoint) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(memo: memo, loginItem: loginItem, onFinished: onFinished)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.isBordered = false
        button.bezelStyle = .inline
        button.image = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 13, weight: .medium))
        button.imagePosition = .imageOnly
        button.contentTintColor = .labelColor
        button.toolTip = "메모 및 설정"
        button.setAccessibilityLabel("메모 및 설정")
        button.target = context.coordinator
        button.action = #selector(Coordinator.openMenu(_:))
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        context.coordinator.onFinished = onFinished
    }

    @MainActor
    final class Coordinator: NSObject {
        let memo: MemoViewModel
        let loginItem: LoginItemModel
        var onFinished: (Bool, NSPoint) -> Void
        private var isTracking = false

        init(memo: MemoViewModel, loginItem: LoginItemModel,
             onFinished: @escaping (Bool, NSPoint) -> Void) {
            self.memo = memo
            self.loginItem = loginItem
            self.onFinished = onFinished
        }

        @objc func openMenu(_ button: NSButton) {
            guard !isTracking else { return }
            isTracking = true
            DispatchQueue.main.async { [weak self, weak button] in
                guard let self else { return }
                guard let button, button.window?.isVisible == true else {
                    self.isTracking = false
                    return
                }
                self.loginItem.refresh()
                let menu = self.makeMenu()
                let anchor = NSPoint(x: button.bounds.minX,
                                     y: button.isFlipped ? button.bounds.maxY + 4 : button.bounds.minY - 4)
                let selectedItem = menu.popUp(positioning: nil, at: anchor, in: button)
                self.isTracking = false
                // The event that ended tracking is authoritative. The system's
                // current pointer position may differ for accessibility clicks.
                let mouseEvents: Set<NSEvent.EventType> = [
                    .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
                    .otherMouseDown, .otherMouseUp
                ]
                let location: NSPoint
                if let event = NSApp.currentEvent, mouseEvents.contains(event.type) {
                    location = event.window?.convertPoint(toScreen: event.locationInWindow) ?? event.locationInWindow
                } else {
                    location = NSEvent.mouseLocation
                }
                self.onFinished(selectedItem, location)
            }
        }

        private func makeMenu() -> NSMenu {
            let menu = NSMenu(title: "메모 및 설정")
            menu.autoenablesItems = false
            let clear = item("메모 비우기", action: #selector(clearMemo), symbol: "trash")
            clear.isEnabled = !memo.text.isEmpty
            menu.addItem(clear)
            let undo = item("되돌리기", action: #selector(undoClear), symbol: "arrow.uturn.backward")
            undo.isEnabled = memo.canUndoClear
            menu.addItem(undo)
            menu.addItem(.separator())
            let login = item("로그인 시 실행", action: #selector(toggleLoginItem))
            login.state = loginItem.isRegistered ? .on : .off
            menu.addItem(login)
            if let message = loginItem.errorMessage ?? loginItem.statusMessage {
                let status = NSMenuItem(title: message, action: nil, keyEquivalent: "")
                status.isEnabled = false
                menu.addItem(status)
            }
            if loginItem.status == .requiresApproval {
                menu.addItem(item("로그인 항목 설정 열기", action: #selector(openLoginSettings)))
            }
            menu.addItem(.separator())
            menu.addItem(item("BookmarkPet 종료", action: #selector(quit)))
            return menu
        }

        private func item(_ title: String, action: Selector, symbol: String? = nil) -> NSMenuItem {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            if let symbol { item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) }
            return item
        }

        @objc private func clearMemo() { memo.clear() }
        @objc private func undoClear() { memo.undoClear() }
        @objc private func toggleLoginItem() { loginItem.setEnabled(!loginItem.isRegistered) }
        @objc private func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }
        @objc private func quit() { NSApp.terminate(nil) }
    }
}

private struct MemoEditor: NSViewRepresentable {
    let text: String
    let onChange: (String) -> Void
    let onReady: (NSTextView) -> Void
    let onEscape: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onChange: onChange, onEscape: onEscape) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        let editor = EscapableTextView(frame: scroll.contentView.bounds)
        editor.minSize = NSSize(width: 0, height: 0)
        editor.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        editor.isVerticallyResizable = true
        editor.isHorizontallyResizable = false
        editor.autoresizingMask = [.width]
        editor.textContainer?.widthTracksTextView = true
        editor.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        editor.isRichText = false
        editor.allowsUndo = true
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.font = .systemFont(ofSize: 13)
        editor.textColor = .labelColor
        editor.drawsBackground = false
        editor.textContainerInset = NSSize(width: 8, height: 7)
        editor.string = text
        editor.delegate = context.coordinator
        editor.onEscape = onEscape
        scroll.documentView = editor
        onReady(editor)
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let editor = scroll.documentView as? NSTextView else { return }
        context.coordinator.onChange = onChange
        context.coordinator.onEscape = onEscape
        if editor.string != text && !editor.hasMarkedText() {
            // Clear/restore replaces the document outside the text undo stack.
            editor.undoManager?.removeAllActions()
            editor.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var onChange: (String) -> Void
        var onEscape: () -> Void

        init(onChange: @escaping (String) -> Void, onEscape: @escaping () -> Void) {
            self.onChange = onChange
            self.onEscape = onEscape
        }

        func textDidChange(_ notification: Notification) {
            guard let editor = notification.object as? NSTextView else { return }
            onChange(editor.string)
        }
    }
}

private final class EscapableTextView: NSTextView {
    var onEscape: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 && !hasMarkedText() {
            onEscape?()
        } else {
            super.keyDown(with: event)
        }
    }
}

private enum BookmarkIcon {
    static func image(hasMemo: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 27, height: 20), flipped: false) { _ in
            NSColor.black.setFill()
            let body = NSBezierPath(roundedRect: NSRect(x: 4, y: 1.5, width: 14, height: 17), xRadius: 3, yRadius: 3)
            body.fill()

            NSGraphicsContext.current?.compositingOperation = .clear
            let notch = NSBezierPath()
            notch.move(to: NSPoint(x: 6, y: 1))
            notch.line(to: NSPoint(x: 11, y: 5.1))
            notch.line(to: NSPoint(x: 16, y: 1))
            notch.close()
            notch.fill()
            NSBezierPath(ovalIn: NSRect(x: 7.2, y: 11.1, width: 1.65, height: 2.0)).fill()
            NSBezierPath(ovalIn: NSRect(x: 13.15, y: 11.1, width: 1.65, height: 2.0)).fill()
            let smile = NSBezierPath()
            smile.move(to: NSPoint(x: 9.1, y: 8.6))
            smile.curve(to: NSPoint(x: 12.9, y: 8.6), controlPoint1: NSPoint(x: 10, y: 7.6), controlPoint2: NSPoint(x: 12, y: 7.6))
            smile.lineWidth = 0.9
            smile.stroke()
            NSGraphicsContext.current?.compositingOperation = .sourceOver

            if hasMemo {
                NSColor.black.setFill()
                NSBezierPath(ovalIn: NSRect(x: 17.2, y: 11.6, width: 8.2, height: 8.2)).fill()
                NSGraphicsContext.current?.compositingOperation = .clear
                NSBezierPath(roundedRect: NSRect(x: 20.6, y: 15.0, width: 1.35, height: 3.3), xRadius: 0.6, yRadius: 0.6).fill()
                NSBezierPath(ovalIn: NSRect(x: 20.65, y: 13.3, width: 1.25, height: 1.25)).fill()
                NSGraphicsContext.current?.compositingOperation = .sourceOver
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
