//
//  SUTouchBarButtonGroup.swift
//  Installer Progress
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Cocoa

@available(macOS 10.12, *)
class SUTouchBarButtonGroup: NSViewController {
    private(set) var buttons: [NSButton]?
    
    init(referencing buttons: [NSButton]) {
        super.init(nibName: nil, bundle: nil)
        
        let buttonGroup = NSView(frame: .zero)
        self.view = view
        
        var constraints: [NSLayoutConstraint] = []
        var buttonCopies: [NSButton] = []
        
        for i in 0..<buttons.count {
            let button = buttons[i]
        
            let buttonCopy = NSButton(title: button.title, target: button.target, action: button.action)
            buttonCopy.tag = button.tag
            buttonCopy.isEnabled = button.isEnabled
            
            // Must be set explicitly, because NSWindow clears it
            // https://github.com/sparkle-project/Sparkle/pull/987#issuecomment-271539319
            if i == 0 {
                buttonCopy.keyEquivalent = "\r"
            }
            
            buttonCopy.translatesAutoresizingMaskIntoConstraints = false
            
            buttonCopies.append(buttonCopy)
            buttonGroup.addSubview(buttonCopy)
            
            // Custom layout is used for equal width buttons, to look more keyboard-like and mimic standard alerts
            // https://github.com/sparkle-project/Sparkle/pull/987#issuecomment-272324726
            constraints.append(NSLayoutConstraint(item: buttonCopy, attribute: .top, relatedBy: .equal, toItem: buttonGroup, attribute: .top, multiplier: 1.0, constant: 0.0))
            constraints.append(NSLayoutConstraint(item: buttonCopy, attribute: .bottom, relatedBy: .equal, toItem: buttonGroup, attribute: .bottom, multiplier: 1.0, constant: 0.0))
            
            if i == 0 {
                constraints.append(NSLayoutConstraint(item: buttonCopy, attribute: .trailing, relatedBy: .equal, toItem: buttonGroup, attribute: .trailing, multiplier: 1.0, constant: 0.0))
            } else {
                constraints.append(NSLayoutConstraint(item: buttonCopy, attribute: .trailing, relatedBy: .equal, toItem: buttonCopies[i - 1], attribute: .leading, multiplier: 1.0, constant: i == 1 ? -8 : -32))
                constraints.append(NSLayoutConstraint(item: buttonCopy, attribute: .width, relatedBy: .equal, toItem: buttonCopies[i - 1], attribute: .width, multiplier: 1, constant: 0))
                constraints.last?.priority = NSLayoutConstraint.Priority(rawValue: 250)
            }
            if i == buttons.count - 1 {
                constraints.append(NSLayoutConstraint(item: buttonCopy, attribute: .leading, relatedBy: .equal, toItem: buttonGroup, attribute: .leading, multiplier: 1.0, constant: 0))
            }
        }
        
        NSLayoutConstraint.activate(constraints)
        self.buttons = buttonCopies
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
