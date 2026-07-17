import AppKit
import SwiftUI
import Combine
import ServiceManagement

#if DEV_BUILD
let projectFolder = "/Users/proninigor/Projects/ip-monit-2"
#endif

final class FloatingPanel: NSPanel {
    var onDoubleClick: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // Двойной клик по окошку открывает меню приложения — на случай, если иконка
    // в меню-баре скрыта из-за нехватки места.
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onDoubleClick?()
            return
        }
        super.mouseDown(with: event)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel!
    private var statusItem: NSStatusItem!
    private var panelMenuItem: NSMenuItem!
    private var compactMenuItem: NSMenuItem!
    private var alignLeftMenuItem: NSMenuItem!
    private var alignRightMenuItem: NSMenuItem!
    private var loginMenuItem: NSMenuItem!
    private var lastPanelFrame: NSRect = .zero
    private var ip4MenuItem: NSMenuItem!
    private var ip6MenuItem: NSMenuItem!
    private var copy4MenuItem: NSMenuItem!
    private var copy6MenuItem: NSMenuItem!
    private let monitor = IPMonitor()
    private var cancellables = Set<AnyCancellable>()

    private var panelVisible: Bool {
        get { UserDefaults.standard.object(forKey: "ShowFloatingPanel") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "ShowFloatingPanel") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPanel()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🏳️"
        rebuildMenu()

        // @Published эмитит на willSet — обрабатываем на следующем тике main queue,
        // когда значение уже записано, иначе читаем устаревшее состояние.
        monitor.$v4.combineLatest(monitor.$v6, monitor.$offline)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in self?.updateStatusItem() }
            .store(in: &cancellables)

        L10n.shared.$lang
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
                self?.updateStatusItem()
            }
            .store(in: &cancellables)

        monitor.$geoMode
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
                self?.updateStatusItem()
            }
            .store(in: &cancellables)

        if panelVisible {
            panel.orderFrontRegardless()
        }
        monitor.start()
    }

    // MARK: - Плавающее окошко

    private func setupPanel() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 26),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none

        let host = NSHostingController(rootView: ContentView(monitor: monitor))
        host.sizingOptions = [.preferredContentSize]
        panel.contentViewController = host
        panel.setContentSize(host.view.fittingSize)

        if !panel.setFrameUsingName("IPMonitPanel"), let screen = NSScreen.main {
            let f = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: f.maxX - panel.frame.width - 16,
                y: f.maxY - panel.frame.height - 16
            ))
        }
        panel.setFrameAutosaveName("IPMonitPanel")
        panel.delegate = self
        panel.onDoubleClick = { [weak self] in self?.showMenuFromWindow() }

        self.panel = panel
        clampPanelToScreen()
        lastPanelFrame = panel.frame
    }

    /// Показывает меню приложения под окошком (дубль меню из трея).
    func showMenuFromWindow() {
        guard let view = panel.contentView, let menu = statusItem?.menu else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: -6), in: view)
    }

    func setPanelVisible(_ visible: Bool) {
        panelVisible = visible
        if visible {
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
        panelMenuItem?.state = visible ? .on : .off
    }

    // Контент меняет размер (IPv4/IPv6/офлайн) — не даём окну уходить за край экрана.
    private func clampPanelToScreen() {
        guard let panel, let screen = panel.screen ?? NSScreen.main else { return }
        let v = screen.visibleFrame
        var origin = panel.frame.origin
        origin.x = min(max(origin.x, v.minX + 4), v.maxX - panel.frame.width - 4)
        origin.y = min(max(origin.y, v.minY + 4), v.maxY - panel.frame.height - 4)
        if origin != panel.frame.origin {
            panel.setFrameOrigin(origin)
        }
    }

    // MARK: - Меню в меню-баре

    private func rebuildMenu() {
        let l10n = L10n.shared
        let menu = NSMenu()
        menu.autoenablesItems = false

        ip4MenuItem = NSMenuItem(title: "IPv4: —", action: nil, keyEquivalent: "")
        ip4MenuItem.isEnabled = false
        menu.addItem(ip4MenuItem)

        ip6MenuItem = NSMenuItem(title: "IPv6: —", action: nil, keyEquivalent: "")
        ip6MenuItem.isEnabled = false
        menu.addItem(ip6MenuItem)

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: l10n.t(.refreshNow), action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        copy4MenuItem = NSMenuItem(title: l10n.t(.copyIPv4), action: #selector(copyIP4), keyEquivalent: "c")
        copy4MenuItem.target = self
        menu.addItem(copy4MenuItem)

        copy6MenuItem = NSMenuItem(title: l10n.t(.copyIPv6), action: #selector(copyIP6), keyEquivalent: "")
        copy6MenuItem.target = self
        menu.addItem(copy6MenuItem)

        menu.addItem(NSMenuItem.separator())

        let geoItem = NSMenuItem(title: l10n.t(.geoModeMenu), action: nil, keyEquivalent: "")
        let geoMenu = NSMenu()
        geoMenu.autoenablesItems = false
        let geoModes: [(GeoMode, L10nKey)] = [
            (.virtualLocation, .geoModeVirtual),
            (.physicalLocation, .geoModePhysical),
        ]
        for (mode, key) in geoModes {
            let item = NSMenuItem(title: l10n.t(key), action: #selector(selectGeoMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = monitor.geoMode == mode ? .on : .off
            geoMenu.addItem(item)
        }
        geoItem.submenu = geoMenu
        menu.addItem(geoItem)

        panelMenuItem = NSMenuItem(title: l10n.t(.floatingWindow), action: #selector(togglePanel), keyEquivalent: "")
        panelMenuItem.target = self
        panelMenuItem.state = panelVisible ? .on : .off
        menu.addItem(panelMenuItem)

        compactMenuItem = NSMenuItem(title: l10n.t(.compactWindow), action: #selector(toggleCompact), keyEquivalent: "")
        compactMenuItem.target = self
        compactMenuItem.state = monitor.compact ? .on : .off
        menu.addItem(compactMenuItem)

        let alignItem = NSMenuItem(title: l10n.t(.alignMenu), action: nil, keyEquivalent: "")
        let alignMenu = NSMenu()
        alignMenu.autoenablesItems = false
        alignLeftMenuItem = NSMenuItem(title: l10n.t(.alignLeft), action: #selector(selectAlignLeft), keyEquivalent: "")
        alignLeftMenuItem.target = self
        alignLeftMenuItem.state = monitor.alignRight ? .off : .on
        alignMenu.addItem(alignLeftMenuItem)
        alignRightMenuItem = NSMenuItem(title: l10n.t(.alignRight), action: #selector(selectAlignRight), keyEquivalent: "")
        alignRightMenuItem.target = self
        alignRightMenuItem.state = monitor.alignRight ? .on : .off
        alignMenu.addItem(alignRightMenuItem)
        alignItem.submenu = alignMenu
        menu.addItem(alignItem)

        loginMenuItem = NSMenuItem(title: l10n.t(.launchAtLogin), action: #selector(toggleLoginItem), keyEquivalent: "")
        loginMenuItem.target = self
        loginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginMenuItem)

        let langItem = NSMenuItem(title: l10n.t(.language), action: nil, keyEquivalent: "")
        let langMenu = NSMenu()
        langMenu.autoenablesItems = false
        for (code, name) in L10n.languages {
            let item = NSMenuItem(title: name, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = code
            item.state = l10n.lang == code ? .on : .off
            langMenu.addItem(item)
        }
        langItem.submenu = langMenu
        menu.addItem(langItem)

        let aboutItem = NSMenuItem(title: l10n.t(.about), action: #selector(showAboutAction), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: l10n.t(.quit), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.delegate = self
        statusItem.menu = menu
    }

    private func updateStatusItem() {
        let l10n = L10n.shared

        if monitor.offline {
            statusItem?.button?.title = "🚫"
            statusItem?.button?.toolTip = l10n.t(.noInternet)
        } else {
            // "⚠️" — страны v4 и v6 не совпали (возможная утечка мимо VPN).
            statusItem?.button?.title = monitor.countryMismatch ? "\(monitor.flag)⚠️" : monitor.flag
            statusItem?.button?.toolTip = nil
        }

        let line4 = monitor.v4.map { "IPv4: \($0.ip) — \(l10n.countryName(monitor.country(of: $0)))" } ?? "IPv4: —"
        let line6 = monitor.v6.map { "IPv6: \($0.ip) — \(l10n.countryName(monitor.country(of: $0)))" } ?? "IPv6: —"
        if !monitor.offline {
            statusItem?.button?.toolTip = "\(line4)\n\(line6)"
        }
        ip4MenuItem?.title = line4
        ip6MenuItem?.title = line6
        copy4MenuItem?.isEnabled = monitor.v4 != nil
        copy6MenuItem?.isEnabled = monitor.v6 != nil
    }

    @objc private func refreshNow() { monitor.refresh(force: true) }

    @objc private func copyIP4() { copyToPasteboard(monitor.v4?.ip) }

    @objc private func copyIP6() { copyToPasteboard(monitor.v6?.ip) }

    private func copyToPasteboard(_ value: String?) {
        guard let value else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    @objc private func togglePanel() { setPanelVisible(!panelVisible) }

    @objc private func toggleCompact() {
        monitor.compact.toggle()
        compactMenuItem?.state = monitor.compact ? .on : .off
    }

    @objc private func selectAlignLeft() { setAlignRight(false) }

    @objc private func selectAlignRight() { setAlignRight(true) }

    private func setAlignRight(_ value: Bool) {
        monitor.alignRight = value
        alignLeftMenuItem?.state = value ? .off : .on
        alignRightMenuItem?.state = value ? .on : .off
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        L10n.shared.lang = code
    }

    @objc private func selectGeoMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = GeoMode(rawValue: raw) else { return }
        monitor.geoMode = mode
    }

    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = L10n.shared.t(.loginItemError)
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        loginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func showAboutAction() { showAbout() }

    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: - About

    func showAbout() {
        let l10n = L10n.shared
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "IPMonit"
        alert.addButton(withTitle: "OK")
        #if DEV_BUILD
        alert.informativeText = l10n.t(.aboutText) + "\n\n"
            + l10n.devSuffix().replacingOccurrences(of: "{path}", with: projectFolder)
        alert.addButton(withTitle: l10n.t(.openProjectFolder))
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(URL(fileURLWithPath: projectFolder))
        }
        #else
        alert.informativeText = l10n.t(.aboutText)
        alert.runModal()
        #endif
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        guard let panel else { return }
        // При Right-выравнивании держим правый край на месте: окно растёт/сжимается влево.
        if monitor.alignRight, lastPanelFrame.width > 0, panel.frame.width != lastPanelFrame.width {
            panel.setFrameOrigin(NSPoint(
                x: lastPanelFrame.maxX - panel.frame.width,
                y: panel.frame.origin.y
            ))
        }
        clampPanelToScreen()
        lastPanelFrame = panel.frame
    }

    func windowDidMove(_ notification: Notification) {
        lastPanelFrame = panel?.frame ?? lastPanelFrame
    }
}

extension AppDelegate: NSMenuDelegate {
    // Состояния могли поменять извне (Системные настройки, контекстное меню окошка).
    func menuWillOpen(_ menu: NSMenu) {
        loginMenuItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
        compactMenuItem?.state = monitor.compact ? .on : .off
        alignLeftMenuItem?.state = monitor.alignRight ? .off : .on
        alignRightMenuItem?.state = monitor.alignRight ? .on : .off
    }
}
