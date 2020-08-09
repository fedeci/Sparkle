//
//  SUStatusController.swift
//  Sparkle
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Cocoa

private let SUStatusControllerTouchBarIndentifier = "" + SPUSparkleBundleIdentifier + ".SUStatusController"

class SUStatusController: NSWindowController {
    @IBOutlet private var actionButton: NSButton!
    @IBOutlet private var progressBar: NSProgressIndicator!
    @IBOutlet private var statusTextField: NSTextField!

    var statusText: String?
    var progressValue: Double?
    var maxProgressValue: Double?
    private var title: String?
    private var buttonTitle: String?
    private var host: SUHost!
    private var touchBarButton: NSButton?

    var isButtonEnabled: Bool {
        get { return actionButton.isEnabled }
        set { actionButton.isEnabled = newValue }
    }

    override var description: String {
        return "\(type(of: self)) <\(host.bundlePath)>"
    }

    var applicationIcon: NSImage {
        return SUApplicationInfo.bestIcon(for: host)
    }

    var progressBarShouldAnimate: Bool {
        return true
    }

    var windowTitle: String {
        return String(format: SULocalizedString("Updating %@"), host.name)
    }

    override var windowNibName: NSNib.Name? {
        return "SUStatus"
    }

    init(with host: SUHost) {
        super.init(window: nil)
        self.host = host
        self.shouldCascadeWindows = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        if SUApplicationInfo.isBackgroundApplication(NSApplication.shared) {
            window?.level = .floating
        }

        window?.center()
        window?.setFrameAutosaveName("SUStatusFrame")
        progressBar.usesThreadedAnimation = true

        if #available(OSX 10.11, *) {
            statusTextField.font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
        }
    }

    // Pass 0 for the max progress value to get an indeterminate progress bar.
    // Pass nil for the status text to not show it.
    func beginAction(with title: String, maxProgressValue: Double, statusText: String) {
        self.title = title

        self.maxProgressValue = maxProgressValue
        self.statusText = statusText
    }

    // If isDefault is YES, the button's key equivalent will be \r.
    func setButtonTitle(_ buttonTitle: String, target: AnyObject?, action: Selector?, isDefault: Bool) {
        self.buttonTitle = buttonTitle

        actionButton.sizeToFit()
        // Except we're going to add 15 px for padding.
        actionButton.setFrameSize(NSSize(width: actionButton.frame.size.width + 15, height: actionButton.frame.size.height))
        // Now we have to move it over so that it's always 15px from the side of the window.
        actionButton.setFrameOrigin(NSPoint(x: window?.frame.size.width ?? 0 - 15 - actionButton.frame.size.width, y: actionButton.frame.origin.y))
        // Redisplay superview to clean up artifacts
        actionButton.superview?.display()

        actionButton.target = target
        actionButton.action = action
        actionButton.keyEquivalent = isDefault ? "\r" : ""

        touchBarButton?.target = actionButton.target
        touchBarButton?.action = actionButton.action
        touchBarButton?.keyEquivalent = actionButton.keyEquivalent

        // 06/05/2008 Alex: Avoid a crash when cancelling during the extraction
        actionButton.isEnabled = target != nil
    }

    func setMaxProgressValue(_ value: Double) {
        let value = value < 0 ? 0 : value
        maxProgressValue = value
        progressValue = 0
        progressBar.isIndeterminate = value == 0
        progressBar.startAnimation(self)
        progressBar.usesThreadedAnimation = true
    }
}

@available(OSX 10.12.2, *)
extension SUStatusController: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.defaultItemIdentifiers = [NSTouchBarItem.Identifier(rawValue: SUStatusControllerTouchBarIndentifier)]
        touchBar.principalItemIdentifier = NSTouchBarItem.Identifier(rawValue: SUStatusControllerTouchBarIndentifier)
        touchBar.delegate = self
        return touchBar
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if identifier.rawValue == SUStatusControllerTouchBarIndentifier {
            let item = NSCustomTouchBarItem(identifier: identifier)
            let group = SUTouchBarButtonGroup(referencing: [actionButton])
            item.viewController = group
            touchBarButton = group.buttons?.first
            touchBarButton?.bind(.title, to: actionButton as Any, withKeyPath: "title", options: nil)
            touchBarButton?.bind(.enabled, to: actionButton as Any, withKeyPath: "enabled", options: nil)
            return item
        }
        return nil
    }
}
