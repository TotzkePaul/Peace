//
//  AppDelegate.swift
//  Peace
//
//  Created by Paul Totzke on 2/8/16.
//  Copyright © 2016 Paul Totzke. All rights reserved.
//

import Cocoa
import AppKit
import Foundation
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    //@IBOutlet weak var window: NSWindow!
    
    // https://nsrover.wordpress.com/2014/10/10/creating-a-os-x-menubar-only-app/
    
    //@property (strong, nonatomic) NSStatusItem *statusItem;
    internal var statusItem: NSStatusItem?;
    
    
    //http://www.xamuel.com/blank-mp3s/
    var sound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("5min.mp3", ofType: nil)!)
    var audioPlayer = AVAudioPlayer()
    var isPlaying:Bool = false
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength);
        
        // TODO: Figure out ho to modify this for dev/test vs production
        ConsoleLog.setCurrentLevel(ConsoleLog.Level.Debug);
        
        setupMenu();
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        NSStatusBar.systemStatusBar().removeStatusItem(statusItem!);
        statusItem = nil;
    }
    
    func setupMenu() {
        // Regenerate menu
        let menu = NSMenu();
        
        
        var state: Int = 0;
        if ( applicationIsInStartUpItems() ) {
            state = 1;
        }
        
        let item:NSMenuItem = NSMenuItem(title: "Launch at startup", action: Selector("toggleLaunchAtStartup"), keyEquivalent: "");
        item.state = state;
        menu.addItem(item);
        menu.addItem(NSMenuItem.separatorItem());
        
        var startItem:NSMenuItem
        var stopItem:NSMenuItem
        
        if isPlaying {
            startItem = NSMenuItem(title: "Start", action: Selector(""), keyEquivalent: "")
            stopItem = NSMenuItem(title: "Stop", action: Selector("stop"), keyEquivalent: "")
        } else {
            startItem = NSMenuItem(title: "Start", action: Selector("start"), keyEquivalent: "")
            stopItem = NSMenuItem(title: "Stop", action: Selector(""), keyEquivalent: "")
        }
        
        menu.addItem(startItem);
        menu.addItem(stopItem);
        menu.addItem(NSMenuItem.separatorItem());
        
        menu.addItem(NSMenuItem(title: "About Peace", action: Selector("about"), keyEquivalent: ""));
        menu.addItem(NSMenuItem.separatorItem());
        menu.addItem(NSMenuItem(title: "Quit IP Menu", action: Selector("terminate:"), keyEquivalent: "q"));
        statusItem!.menu = menu;
        
        
        statusItem!.title = "\u{262F}"
    }
    
    func about() {
        if let checkURL = NSURL(string: "http://www.totzkepaul.com") {
            NSWorkspace.sharedWorkspace().openURL(checkURL);
        }
    }
    
    func stop() {
        audioPlayer.stop()
        isPlaying = false
        setupMenu()
    }
    
    func start() {
        do{
            audioPlayer = try AVAudioPlayer(contentsOfURL: sound, fileTypeHint:nil)
            audioPlayer.numberOfLoops = -1;
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch {}
        isPlaying = true
        setupMenu()
    }
    
    func dialogOKCancel(question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.WarningAlertStyle
        myPopup.addButtonWithTitle("OK")
        myPopup.addButtonWithTitle("Cancel")
        let res = myPopup.runModal()
        if res == NSAlertFirstButtonReturn {
            return true
        }
        return false
    }
    
    // http://stackoverflow.com/questions/26475008/swift-getting-a-mac-app-to-launch-on-startup
    func applicationIsInStartUpItems() -> Bool {
        return (itemReferencesInLoginItems().existingReference != nil)
    }
    
    func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItemRef?, lastReference: LSSharedFileListItemRef?) {
        if let appUrl : NSURL = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
            let loginItemsRef = LSSharedFileListCreate(
                nil,
                kLSSharedFileListSessionLoginItems.takeRetainedValue(),
                nil
                ).takeRetainedValue() as LSSharedFileListRef?
            if loginItemsRef != nil {
                let loginItems: NSArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
                if ( loginItems.count > 0 ) {
                    let lastItemRef: LSSharedFileListItemRef = loginItems.lastObject as! LSSharedFileListItemRef
                    for var i = 0; i < loginItems.count; ++i {
                        let currentItemRef: LSSharedFileListItemRef = loginItems.objectAtIndex(i) as! LSSharedFileListItemRef
                        if let urlRef: Unmanaged<CFURL> = LSSharedFileListItemCopyResolvedURL(currentItemRef, 0, nil) {
                            let urlRef:NSURL = urlRef.takeRetainedValue();
                            if urlRef.isEqual(appUrl) {
                                return (currentItemRef, lastItemRef)
                            }
                        } else {
                            print("Unknown login application");
                        }
                    }
                    //The application was not found in the startup list
                    return (nil, lastItemRef)
                } else {
                    let addatstart: LSSharedFileListItemRef = kLSSharedFileListItemBeforeFirst.takeRetainedValue()
                    return(nil,addatstart)
                }
            }
        }
        return (nil, nil)
    }
    
    func toggleLaunchAtStartup() {
        let itemReferences = itemReferencesInLoginItems()
        let shouldBeToggled = (itemReferences.existingReference == nil)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
            ).takeRetainedValue() as LSSharedFileListRef?
        if loginItemsRef != nil {
            if shouldBeToggled {
                if let appUrl : CFURLRef = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
                    LSSharedFileListInsertItemURL(
                        loginItemsRef,
                        itemReferences.lastReference,
                        nil,
                        nil,
                        appUrl,
                        nil,
                        nil
                    )
                    print("Application was added to login items")
                }
            } else {
                if let itemRef = itemReferences.existingReference {
                    LSSharedFileListItemRemove(loginItemsRef,itemRef);
                    print("Application was removed from login items")
                }
            }
        }
    }
    
}



