//
//  KeyboardViewController.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import AudioToolbox
import SnapKit
import MMWormhole

// TODO: move this somewhere else and localize
//let kAutoCapitalization = "kAutoCapitalization"
//let kPeriodShortcut = "kPeriodShortcut"
//let kKeyboardClicks = "kKeyboardClicks"
//let kSmallLowercase = "kSmallLowercase"

class KeyboardViewController: UIInputViewController {

    let backspaceDelay: TimeInterval = 0.5
    let backspaceRepeat: TimeInterval = 0.07
    
    var keyboard: Keyboard!
    var forwardingView: ForwardingView!
    var layout: KeyboardLayout?
    var heightConstraint: NSLayoutConstraint?
    
    var lexicon: UILexicon?
    
//    var selectedRecipientsView: SelectedRecipientView?
    
    var currentMode: Int = 0 {
        didSet {
            if oldValue != currentMode {
                setMode(currentMode)
            }
        }
    }
    
    var backspaceActive: Bool {
        get {
            return (backspaceDelayTimer != nil) || (backspaceRepeatTimer != nil)
        }
    }
    var backspaceDelayTimer: Timer?
    var backspaceRepeatTimer: Timer?
    
    var previousPasteboardCount: Int?
    var pasteboardObserveTimer: Timer?
    
    enum AutoPeriodState {
        case noSpace
        case firstSpace
    }
    
    var autoPeriodState: AutoPeriodState = .noSpace
    var lastCharCountInBeforeContext: Int = 0
    
    var shiftState: ShiftState = .disabled {
        didSet {
            switch shiftState {
            case .disabled:
                self.updateKeyCaps(false)
            case .enabled:
                self.updateKeyCaps(true)
            case .locked:
                self.updateKeyCaps(true)
            }
        }
    }
    
    // state tracking during shift tap
    var shiftWasMultitapped: Bool = false
    var shiftStartingState: ShiftState?
    
//    var originHeight: CGFloat = 0
    
    var keyboardHeight: CGFloat {
        get {
            if let constraint = self.heightConstraint {
                return constraint.constant
            }
            else {
                return 0
            }
        }
        set {
            self.setHeight(newValue)
        }
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestSupplementaryLexicon { lexicon in
            self.lexicon = lexicon
        }
        
        if #available(iOSApplicationExtension 11.0, *) {
            if hasFullAccess {
                let name = KeyboardPreference.accountName
                if let accoutName = name {
                    print("name: \(accoutName)")
                } else {
                    print("no name")
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
        if #available(iOSApplicationExtension 11.0, *) {
            self.keyboard = defaultKeyboard(needInputSwitchKey: needsInputModeSwitchKey)
        } else {
            self.keyboard = defaultKeyboard(needInputSwitchKey: true)
        }
        self.shiftState = .disabled
        self.currentMode = 0
        
        self.forwardingView = ForwardingView(frame: CGRect.zero)
        self.view.addSubview(self.forwardingView)
        
//        selectedRecipientsView = SelectedRecipientView(frame: .zero)
//        view.insertSubview(selectedRecipientsView!, belowSubview: forwardingView)
//
//        selectedRecipientsView?.snp.makeConstraints { make in
//            make.leading.trailing.equalToSuperview()
//            make.bottom.equalTo(self.forwardingView.snp.top)
//            make.height.equalTo(metrics[.recipientsBanner]!)
//        }

        KeyboardModeManager.shared.keyboardVC = self
        KeyboardModeManager.shared.setupSubViews()
        
        setupLayout()
    }
    
    // without this here kludge, the height constraint for the keyboard does not work for some reason
    var kludge: UIView?
    func setupKludge() {
        if self.kludge == nil {
            let kludge = UIView()
            self.view.addSubview(kludge)
            kludge.translatesAutoresizingMaskIntoConstraints = false
            kludge.isHidden = true
            
            let a = NSLayoutConstraint(item: kludge, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0)
            let b = NSLayoutConstraint(item: kludge, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0)
            let c = NSLayoutConstraint(item: kludge, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
            let d = NSLayoutConstraint(item: kludge, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
            self.view.addConstraints([a, b, c, d])
            
            self.kludge = kludge
        }
    }
    
    deinit {
        backspaceDelayTimer?.invalidate()
        backspaceRepeatTimer?.invalidate()
        pasteboardObserveTimer?.invalidate()
    }
    
    /*
     BUG NOTE
     
     For some strange reason, a layout pass of the entire keyboard is triggered
     whenever a popup shows up, if one of the following is done:
     
     a) The forwarding view uses an autoresizing mask.
     b) The forwarding view has constraints set anywhere other than init.
     
     On the other hand, setting (non-autoresizing) constraints or just setting the
     frame in layoutSubviews works perfectly fine.
     
     I don't really know what to make of this. Am I doing Autolayout wrong, is it
     a bug, or is it expected behavior? Perhaps this has to do with the fact that
     the view's frame is only ever explicitly modified when set directly in layoutSubviews,
     and not implicitly modified by various Autolayout constraints
     (even though it should really not be changing).
     */
    
    var constraintsAdded: Bool = false
    func setupLayout() {
        if !constraintsAdded {
            self.layout = type(of: self).layoutClass.init(model: self.keyboard, superview: self.forwardingView, layoutConstants: type(of: self).layoutConstants, globalColors: type(of: self).globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
            
            self.layout?.initialize()
            self.setMode(0)
            
            self.setupKludge()
            
            self.updateKeyCaps(self.shiftState.uppercase())
            self.updateCapsIfNeeded()
            
            self.updateAppearances(self.darkMode())
            self.addInputTraitsObservers()
            
            self.constraintsAdded = true
        }
    }
    
    // only available after frame becomes non-zero
    func darkMode() -> Bool {
        let darkMode = { () -> Bool in
            let proxy = self.textDocumentProxy
            return proxy.keyboardAppearance == UIKeyboardAppearance.dark
        }()
        
        return darkMode
    }
    
    func solidColorMode() -> Bool {
//        return UIAccessibility.isReduceTransparencyEnabled
        return true
    }
    
    var lastLayoutBounds: CGRect?
    override func viewDidLayoutSubviews() {
        if view.bounds == CGRect.zero {
            return
        }
        
        self.setupLayout()
        
        let orientationSavvyBounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.height(forOrientation: self.interfaceOrientation, withTopBanner: false))
        
        if (lastLayoutBounds != nil && lastLayoutBounds == orientationSavvyBounds) {
            // do nothing
        }
        else {
            let uppercase = self.shiftState.uppercase()
            let characterUppercase = KeyboardPreference.kSmallLowercase ? uppercase : true
            
            self.forwardingView.frame = orientationSavvyBounds
            self.layout?.layoutKeys(self.currentMode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
            self.lastLayoutBounds = orientationSavvyBounds
            self.setupKeys()
        }
        
        let newOrigin = CGPoint(x: 0, y: self.view.bounds.height - self.forwardingView.bounds.height)
        self.forwardingView.frame.origin = newOrigin
        
        
    }
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        self.bannerView?.isHidden = false
        self.keyboardHeight = self.height(forOrientation: self.interfaceOrientation, withTopBanner: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Schedule a timer to continously detect if pasteboard content changes
        // https://stackoverflow.com/questions/26868751/nsnotificationcenter-pasteboardchangednotification-not-firing
        if let timer = pasteboardObserveTimer, timer.isValid {
            // Timer is still running, do nothing
        } else {
            pasteboardObserveTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkPasteboard), userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pasteboardObserveTimer?.invalidate()
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        // optimization: ensures smooth animation
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = true
            }
        }
        adjustHeight(delta: KeyboardModeManager.shared.mode.keyboardExtraHeight)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        // optimization: ensures quick mode and shift transitions
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = false
            }
        }
    }
    
    func height(forOrientation orientation: UIInterfaceOrientation, withTopBanner: Bool) -> CGFloat {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        
        // AB: consider re-enabling this when interfaceOrientation actually breaks
        //// HACK: Detecting orientation manually
        //let screenSize: CGSize = UIScreen.main.bounds.size
        //let orientation: UIInterfaceOrientation = screenSize.width < screenSize.height ? .portrait : .landscapeLeft
        
        //TODO: hardcoded stuff
        let actualScreenWidth = (UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale)
        let canonicalPortraitHeight: CGFloat
        let canonicalLandscapeHeight: CGFloat
        if isPad {
            canonicalPortraitHeight = 264
            canonicalLandscapeHeight = 352
        }
        else {
            canonicalPortraitHeight = orientation.isPortrait && actualScreenWidth >= 400 ? 226 : 216
            canonicalLandscapeHeight = 162
        }
        let topBannerHeight = (withTopBanner ? metrics[.recipientsBanner] : 0)!
        
        return CGFloat(orientation.isPortrait ? canonicalPortraitHeight + topBannerHeight : canonicalLandscapeHeight + topBannerHeight)
    }
    
    /*
     BUG NOTE
     
     None of the UIContentContainer methods are called for this controller.
     */
    
    //override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    //    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    //}
    
    func setupKeys() {
        if self.layout == nil {
            return
        }
        
        for page in keyboard.pages {
            for rowKeys in page.rows { // TODO: quick hack
                for key in rowKeys {
                    if let keyView = self.layout?.viewForKey(key) {
                        keyView.removeTarget(nil, action: nil, for: .allEvents)
                        
                        switch key.type {
                        case Key.TCKeyboardKeyType.keyboardChange:
                            
                            keyView.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
                            continue
//                            continue
//                            keyView.addTarget(self,
//                                              action: #selector(KeyboardViewController.advanceTapped(_:)),
//                                              for: .touchUpInside)
                        case Key.TCKeyboardKeyType.backspace:
                            let cancelEvents: UIControl.Event = [.touchUpInside, .touchUpInside, .touchDragExit, .touchUpOutside, .touchCancel, .touchDragOutside]
                            
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.backspaceDown(_:)),
                                              for: .touchDown)
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.backspaceUp(_:)),
                                              for: cancelEvents)
                        case Key.TCKeyboardKeyType.shift:
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.shiftDown(_:)),
                                              for: .touchDown)
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.shiftUp(_:)),
                                              for: .touchUpInside)
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.shiftDoubleTapped(_:)),
                                              for: .touchDownRepeat)
                        case Key.TCKeyboardKeyType.modeChange:
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.modeChangeTapped(_:)),
                                              for: .touchDown)
                        case Key.TCKeyboardKeyType.settings:
                            break
//                            keyView.addTarget(self,
//                                              action: #selector(KeyboardViewController.toggleSettings),
//                                              for: .touchUpInside)
                        default:
                            break
                        }
                        
                        if key.isCharacter {
                            if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
                                keyView.addTarget(self,
                                                  action: #selector(KeyboardViewController.showPopup(_:)),
                                                  for: [.touchDown, .touchDragInside, .touchDragEnter])
                                keyView.addTarget(keyView,
                                                  action: #selector(KeyboardKey.hidePopup),
                                                  for: [.touchDragExit, .touchCancel])
                                keyView.addTarget(self,
                                                  action: #selector(KeyboardViewController.hidePopupDelay(_:)),
                                                  for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
                            }
                        }
                        
                        if key.hasOutput {
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.keyPressedHelper(_:)),
                                              for: .touchUpInside)
                        }
                        
                        if key.type != Key.TCKeyboardKeyType.shift && key.type != Key.TCKeyboardKeyType.modeChange {
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.highlightKey(_:)),
                                              for: [.touchDown, .touchDragInside, .touchDragEnter])
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.unHighlightKey(_:)),
                                              for: [.touchUpInside, .touchUpOutside, .touchDragOutside, .touchDragExit, .touchCancel])
                        }
                        
                        keyView.addTarget(self,
                                          action: #selector(KeyboardViewController.playKeySound),
                                          for: .touchDown)
                    }
                }
            }
        }
    }
    
    /////////////////
    // POPUP DELAY //
    /////////////////
    
    var keyWithDelayedPopup: KeyboardKey?
    var popupDelayTimer: Timer?
    
    @objc func showPopup(_ sender: KeyboardKey) {
        if sender == self.keyWithDelayedPopup {
            self.popupDelayTimer?.invalidate()
        }
        sender.showPopup()
    }
    
    @objc func hidePopupDelay(_ sender: KeyboardKey) {
        self.popupDelayTimer?.invalidate()
        
        if sender != self.keyWithDelayedPopup {
            self.keyWithDelayedPopup?.hidePopup()
            self.keyWithDelayedPopup = sender
        }
        
        if sender.popup != nil {
            self.popupDelayTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(KeyboardViewController.hidePopupCallback), userInfo: nil, repeats: false)
        }
    }
    
    @objc func hidePopupCallback() {
        self.keyWithDelayedPopup?.hidePopup()
        self.keyWithDelayedPopup = nil
        self.popupDelayTimer = nil
    }
    
    /////////////////////
    // POPUP DELAY END //
    /////////////////////
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
    
    // TODO: this is currently not working as intended; only called when selection changed -- iOS bug
    override func textDidChange(_ textInput: UITextInput?) {
        self.contextChanged()
    }
    
    override func selectionDidChange(_ textInput: UITextInput?) {
        KeyboardModeManager.shared.contextDidChange()
    }
    
    func contextChanged() {
        KeyboardModeManager.shared.mode = .typing
        self.updateCapsIfNeeded()
        self.autoPeriodState = .noSpace
        KeyboardModeManager.shared.contextDidChange()
    }
    
    func setHeight(_ height: CGFloat) {
        if self.heightConstraint == nil {
            self.heightConstraint = NSLayoutConstraint(
                item:self.view,
                attribute:.height,
                relatedBy:.equal,
                toItem:nil,
                attribute:.notAnAttribute,
                multiplier:0,
                constant:height)
            
            // https://github.com/archagon/tasty-imitation-keyboard/issues/93
            self.heightConstraint!.priority = .init(rawValue: 900)
            
            self.view.addConstraint(self.heightConstraint!) // TODO: what if view already has constraint added?
//            if originHeight == 0 {
//                // Store the keybaord origin height once the view's bounds height is not zero.
//                originHeight = height
//            }
        }
        else {
            self.heightConstraint?.constant = height
        }
    }
    
    func adjustHeight(delta: CGFloat) {
        let originHeight = height(forOrientation: self.interfaceOrientation, withTopBanner: true)
        let newHeight = originHeight + delta
        keyboardHeight = newHeight
    }
    
    func updateAppearances(_ appearanceIsDark: Bool) {
        self.layout?.solidColorMode = self.solidColorMode()
        self.layout?.darkMode = appearanceIsDark
        self.layout?.updateKeyAppearance()
        
        if(!appearanceIsDark){
            self.forwardingView?.backgroundColor = UIColor(displayP3Red: (203.0/255.0), green: (206.0/255.0), blue: (226.0/255.0), alpha: 0.1)
        }else{
//            self.forwardingView?.backgroundColor = UIColor(displayP3Red: (42.0/255.0), green: (43.0/255.0), blue: (53.0/255.0), alpha: 0.1)
            self.forwardingView?.backgroundColor = .keyboardBackgroundDark
        }
        
        updateSubviewTheme(toUpdateView: view, appearanceIsDark)
    }
    
    private func updateSubviewTheme(toUpdateView: UIView, _ appearanceIsDark: Bool) {
        for subview in toUpdateView.subviews {
            if let thematic = subview as? Thematic {
                thematic.updateColor(theme: appearanceIsDark ? .dark : .light)
            }
            if !subview.subviews.isEmpty {
                updateSubviewTheme(toUpdateView: subview, appearanceIsDark)
            }
        }
    }
    
    @objc func highlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = true
    }
    
    @objc func unHighlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = false
    }
    
    @objc func keyPressedHelper(_ sender: KeyboardKey) {
        if let model = self.layout?.keyForView(sender) {
            self.keyPressed(model)
            
            // auto exit from special char subkeyboard
            if model.type == Key.TCKeyboardKeyType.space || model.type == Key.TCKeyboardKeyType.return {
                self.currentMode = 0
            }
            else if model.lowercaseOutput == "'" {
                self.currentMode = 0
            }
            else if model.type == Key.TCKeyboardKeyType.character {
                self.currentMode = 0
            }
            
            // auto period on double space
            // TODO: timeout
            
            self.handleAutoPeriod(model)
            // TODO: reset context
        }
        
        self.updateCapsIfNeeded()
    }
    
    func handleAutoPeriod(_ key: Key) {
        if !KeyboardPreference.kPeriodShortcut {
            return
        }
        
        if self.autoPeriodState == .firstSpace {
            if key.type != Key.TCKeyboardKeyType.space {
                self.autoPeriodState = .noSpace
                return
            }
            
            let charactersAreInCorrectState = { () -> Bool in
                let previousContext = self.textDocumentProxy.documentContextBeforeInput
                
                if previousContext == nil || (previousContext!).count < 3 {
                    return false
                }
                
                var index = previousContext!.endIndex
                
                index = previousContext!.index(before: index)
                if previousContext![index] != " " {
                    return false
                }
                
                index = previousContext!.index(before: index)
                if previousContext![index] != " " {
                    return false
                }
                
                index = previousContext!.index(before: index)
                let char = previousContext![index]
                if self.characterIsWhitespace(char) || self.characterIsPunctuation(char) || char == "," {
                    return false
                }
                
                return true
            }()
            
            if charactersAreInCorrectState {
                KeyboardModeManager.shared.deleteBackward()
                KeyboardModeManager.shared.deleteBackward()
                KeyboardModeManager.shared.insertKey(".")
                KeyboardModeManager.shared.insertKey(" ")
//                self.textDocumentProxy.deleteBackward()
//                self.textDocumentProxy.deleteBackward()
//                self.textDocumentProxy.insertText(".")
//                self.textDocumentProxy.insertText(" ")
            }
            
            self.autoPeriodState = .noSpace
        }
        else {
            if key.type == Key.TCKeyboardKeyType.space {
                self.autoPeriodState = .firstSpace
            }
        }
    }
    
    func cancelBackspaceTimers() {
        self.backspaceDelayTimer?.invalidate()
        self.backspaceRepeatTimer?.invalidate()
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = nil
    }
    
    @objc func backspaceDown(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
        KeyboardModeManager.shared.deleteBackward()
//        self.textDocumentProxy.deleteBackward()
        self.updateCapsIfNeeded()
        
        // trigger for subsequent deletes
        self.backspaceDelayTimer = Timer.scheduledTimer(timeInterval: backspaceDelay - backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceDelayCallback), userInfo: nil, repeats: false)
    }
    
    @objc func backspaceUp(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
    }
    
    @objc func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = Timer.scheduledTimer(timeInterval: backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceRepeatCallback), userInfo: nil, repeats: true)
    }
    
    @objc func backspaceRepeatCallback() {
        self.playKeySound()
        KeyboardModeManager.shared.deleteBackward()
//        self.textDocumentProxy.deleteBackward()
        self.updateCapsIfNeeded()
    }
    
    @objc func shiftDown(_ sender: KeyboardKey) {
        self.shiftStartingState = self.shiftState
        
        if let shiftStartingState = self.shiftStartingState {
            if shiftStartingState.uppercase() {
                // handled by shiftUp
                return
            }
            else {
                switch self.shiftState {
                case .disabled:
                    self.shiftState = .enabled
                case .enabled:
                    self.shiftState = .disabled
                case .locked:
                    self.shiftState = .disabled
                }
                
                (sender.shape as? ShiftShape)?.withLock = false
            }
        }
    }
    
    @objc func shiftUp(_ sender: KeyboardKey) {
        if self.shiftWasMultitapped {
            // do nothing
        }
        else {
            if let shiftStartingState = self.shiftStartingState {
                if !shiftStartingState.uppercase() {
                    // handled by shiftDown
                }
                else {
                    switch self.shiftState {
                    case .disabled:
                        self.shiftState = .enabled
                    case .enabled:
                        self.shiftState = .disabled
                    case .locked:
                        self.shiftState = .disabled
                    }
                    
                    (sender.shape as? ShiftShape)?.withLock = false
                }
            }
        }
        
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
    }
    
    @objc func shiftDoubleTapped(_ sender: KeyboardKey) {
        self.shiftWasMultitapped = true
        
        switch self.shiftState {
        case .disabled:
            self.shiftState = .locked
        case .enabled:
            self.shiftState = .locked
        case .locked:
            self.shiftState = .disabled
        }
    }
    
    func updateKeyCaps(_ uppercase: Bool) {
        let characterUppercase = KeyboardPreference.kSmallLowercase ? uppercase : true
        self.layout?.updateKeyCaps(false, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
    }
    
    @objc func modeChangeTapped(_ sender: KeyboardKey) {
        if let toMode = self.layout?.viewToModel[sender]?.toMode {
            self.currentMode = toMode
        }
    }
    
    func setMode(_ mode: Int) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        let uppercase = self.shiftState.uppercase()
        let characterUppercase = KeyboardPreference.kSmallLowercase ? uppercase : true
        self.layout?.layoutKeys(mode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
        
        self.setupKeys()
    }
    
    @objc func advanceTapped(_ sender: KeyboardKey) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        self.advanceToNextInputMode()
    }
    
    func updateCapsIfNeeded() {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .enabled
            case .enabled:
                self.shiftState = .enabled
            case .locked:
                self.shiftState = .locked
            }
        }
        else {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .disabled
            case .enabled:
                self.shiftState = .disabled
            case .locked:
                self.shiftState = .locked
            }
        }
    }
    
    func characterIsPunctuation(_ character: Character) -> Bool {
        return (character == ".") || (character == "!") || (character == "?")
    }
    
    func characterIsNewline(_ character: Character) -> Bool {
        return (character == "\n") || (character == "\r")
    }
    
    func characterIsWhitespace(_ character: Character) -> Bool {
        // there are others, but who cares
        return (character == " ") || (character == "\n") || (character == "\r") || (character == "\t")
    }
    
    func stringIsWhitespace(_ string: String?) -> Bool {
        if string != nil {
            for char in string! {
                if !characterIsWhitespace(char) {
                    return false
                }
            }
        }
        return true
    }
    
    func shouldAutoCapitalize() -> Bool {
        if !KeyboardPreference.kAutoCapitalization {
            return false
        }
        
        let traits = self.textDocumentProxy
        if let autocapitalization = traits.autocapitalizationType {
            let documentProxy = self.textDocumentProxy
            //var beforeContext = documentProxy.documentContextBeforeInput
            
            switch autocapitalization {
            case .none:
                return false
            case .words:
                if let beforeContext = documentProxy.documentContextBeforeInput {
                    let previousCharacter = beforeContext[beforeContext.index(before: beforeContext.endIndex)]
                    return self.characterIsWhitespace(previousCharacter)
                }
                else {
                    return true
                }
                
            case .sentences:
                if let beforeContext = documentProxy.documentContextBeforeInput {
                    let offset = min(3, beforeContext.count)
                    var index = beforeContext.endIndex
                    
                    for i in 0 ..< offset {
                        index = beforeContext.index(before: index)
                        let char = beforeContext[index]
                        
                        if characterIsPunctuation(char) {
                            if i == 0 {
                                return false //not enough spaces after punctuation
                            }
                            else {
                                return true //punctuation with at least one space after it
                            }
                        }
                        else {
                            if !characterIsWhitespace(char) {
                                return false //hit a foreign character before getting to 3 spaces
                            }
                            else if characterIsNewline(char) {
                                return true //hit start of line
                            }
                        }
                    }
                    
                    return true //either got 3 spaces or hit start of line
                }
                else {
                    return true
                }
            case .allCharacters:
                return true
            }
        }
        else {
            return false
        }
    }
    
    // this only works if full access is enabled
    @objc func playKeySound() {
        if !KeyboardPreference.kKeyboardClicks {
            return
        }
        
        
        DispatchQueue.main.async {
            UIDevice.current.playInputClick()
        }
    }
    
    //////////////////////////////////////
    // MOST COMMONLY EXTENDABLE METHODS //
    //////////////////////////////////////
    
    class var layoutClass: KeyboardLayout.Type { get { return KeyboardLayout.self }}
    class var layoutConstants: LayoutConstants.Type { get { return LayoutConstants.self }}
    class var globalColors: GlobalColors.Type { get { return GlobalColors.self }}
    
    func keyPressed(_ key: Key) {
        KeyboardModeManager.shared.insertKey(key.outputForCase(self.shiftState.uppercase()))
//        self.textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase()))
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
}

extension KeyboardViewController {
    
    static var mainAppBundleID: String {
        return "com.Sujitech.TesserCube"
    }
    
    func isRunningInsideMainApp() -> Bool {
        if let parentViewController = self.parent {
            if let hostBundleID = parentViewController.value(forKey: "_hostBundleID") as? String {
                return hostBundleID == KeyboardViewController.mainAppBundleID
            }
        }
        return false
    }
    
    @objc
    func checkPasteboard() {
        guard !isRunningInsideMainApp() else {
            return
        }
        guard UIPasteboard.general.changeCount != previousPasteboardCount else {
            return
        }
        previousPasteboardCount = UIPasteboard.general.changeCount
        KeyboardModeManager.shared.checkPasteboard()
    }
}
