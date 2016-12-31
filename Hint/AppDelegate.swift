//
//  AppDelegate.swift
//  Reminder
//
//  Created by Christopher Smith on 12/18/16.
//  Copyright © 2016 Chris Smith. All rights reserved.
//

import Cocoa

enum TextType: Int {
    case reminder = 0
}

enum SoundType: Int {
    case silent = 0
}

func linkFromString(_ string: String) -> NSAttributedString {
    let attr = NSMutableAttributedString(string: string)
    let range = NSMakeRange(0, attr.length)
    
    attr.beginEditing()
    attr.addAttribute(NSLinkAttributeName, value: "https://github.com/crsmithdev/hint", range: range)
    attr.addAttribute(NSForegroundColorAttributeName, value: NSColor.blue, range: range)
    attr.addAttribute(NSUnderlineStyleAttributeName, value: 1, range: range)
    //attr.addAttribute(NSFontAttributeName, value: NSFont(name: "Helvetica Neue", size: 13), range: range)
    attr.endEditing()
    
    return attr
}

class SubTextView: NSTextView {
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: NSCursor.arrow())
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet var aboutPanel: NSPanel!
    @IBOutlet var menu: NSMenu!
    @IBOutlet var button: NSButton!

    let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    
    var notifyTimer: Timer?
    var notifyInterval: Int = 300
    var pauseTimer: Timer?
    var pauseInterval: Int = 0
    var paused: Bool = false
    
    var textType = TextType.reminder
    var textSource: TextSource!
    
    /* Lifecycle */
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        statusItem.button?.image = NSImage(named: "MenuBarIcon")
        statusItem.menu = menu!
        
        let str = linkFromString("github.com/crsmithdev/hint")
        button.attributedStringValue = str
        button.attributedTitle = str

        load(text: textType)
        schedule(seconds: notifyInterval)
        //play()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) { }
    
    /* Actions */
    
    @IBAction func actionLinkClick(_ sender: NSButton) {
        NSWorkspace.shared().open(URL(string: "https://github.com/crsmithdev/hint")!)
    }
    
    @IBAction func actionAbout(_ sender: NSMenuItem) {
        NSApplication.shared().activate(ignoringOtherApps: true)
        aboutPanel.orderFront(self)
    }
    
    @IBAction func actionChangeInterval(_ sender: NSMenuItem) {
        schedule(seconds: sender.tag)
    }
    
    @IBAction func actionPause(_ sender: NSMenuItem) {
        if sender.tag > 0 {
            pause(seconds: sender.tag)
        } else {
            pause()
        }
    }
    
    @IBAction func actionResume(_ sender: NSMenuItem) {
        resume()
    }
    
    @IBAction func actionChangeText(_ sender: NSMenuItem) {
        textType = TextType.init(rawValue: sender.tag)!
        load(text: textType)
    }
    
    @IBAction func actionQuit(_ sender: AnyObject) {
        NSApplication.shared().terminate(self)
    }
    
    /* Menu */
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        if menuItem.action == #selector(self.actionChangeInterval) {
            menuItem.state = menuItem.tag == notifyInterval ? 1 : 0
            return true
        }
        
        if menuItem.action == #selector(self.actionPause) {
            menuItem.state = paused && menuItem.tag == pauseInterval ? 1 : 0
            return true
        }
        
        if menuItem.action == #selector(self.actionChangeText) {
            menuItem.state = menuItem.tag == textType.rawValue ? 1 : 0
            return true
        }
        
        if menuItem.action == #selector(self.actionResume) {
            return paused
        }
        
        return true
    }
    
    /* Logic */
    
    func schedule(seconds: Int) {
        
        notifyInterval = Int(seconds)
        
        notifyTimer?.invalidate()
        notifyTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(seconds),
            target: self,
            selector: #selector(self.notify),
            userInfo: nil,
            repeats: true
        )
        
        DLog("scheduled for \(seconds)s")
    }
    
    func pause() {
        
        pauseInterval = 0
        pauseTimer?.invalidate()
        paused = true
    }
    
    func pause(seconds: Int) {
        
        paused = true
        pauseInterval = seconds
        
        pauseTimer?.invalidate()
        pauseTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(seconds),
            target: self,
            selector: #selector(self.resume),
            userInfo: nil,
            repeats: false
        )
        
        DLog("paused for \(pauseInterval)s")
    }
    
    func resume() {
        pauseInterval = 0
        paused = false
        DLog("resumed")
    }
    
    func notify() {
        
        if paused {
            DLog("skipping notification, paused")
            return
        }
        
        let text = textSource.next()
        Notifier.shared.notify(text: text)
        //play()
        
        DLog("notified '\(text)'")
    }
    
    func load(text: TextType) {
        // TODO error handling
        
        let path = Bundle.main.path(forResource: "\(text)", ofType: "txt")!
        textSource = try? TextSource.fromAsset(name: "Text/Reminder")
    }
    
    func play() {
        if let sound = NSDataAsset(name: "SingingBowlLow") {
            let s = NSSound(data: sound.data)
            s?.play()
        }
    }
}





