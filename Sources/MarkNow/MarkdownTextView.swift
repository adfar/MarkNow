import UIKit

public protocol MarkdownTextViewDelegate: AnyObject {
    func markdownTextViewDidChange(_ textView: MarkdownTextView)
    func markdownTextView(_ textView: MarkdownTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
}

public class MarkdownTextView: UIView {
    
    // MARK: - Public Properties
    
    public weak var delegate: MarkdownTextViewDelegate?
    
    public var text: String {
        get { markdownTextStorage.string }
        set { 
            markdownTextStorage.replaceCharacters(in: NSRange(location: 0, length: markdownTextStorage.length), with: newValue)
            // When setting text programmatically, position cursor at beginning
            textView.selectedRange = NSRange(location: 0, length: 0)
            markdownTextStorage.updateCursorPosition(0)
        }
    }
    
    public var font: UIFont {
        get { markdownTextStorage.font ?? UIFont.systemFont(ofSize: 16) }
        set { 
            markdownTextStorage.setDefaultFont(newValue)
            textView.font = newValue
        }
    }
    
    public var textColor: UIColor {
        get { markdownTextStorage.textColor ?? UIColor.label }
        set { 
            markdownTextStorage.setDefaultTextColor(newValue)
            textView.textColor = newValue
        }
    }
    
    public var isEditable: Bool {
        get { textView.isEditable }
        set { textView.isEditable = newValue }
    }
    
    public var selectedRange: NSRange {
        get { textView.selectedRange }
        set { textView.selectedRange = newValue }
    }
    
    // MARK: - Private Properties
    
    private let textStorage = MarkdownTextStorage()
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer()
    private let textView: UITextView
    
    // MARK: - Internal Properties
    
    internal var markdownTextStorage: MarkdownTextStorage {
        return textStorage
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        // Connect TextKit stack first
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        // Now create UITextView with connected textContainer
        textView = UITextView(frame: frame, textContainer: textContainer)
        super.init(frame: frame)
        setupTextKit()
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        // Connect TextKit stack first
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        // Create UITextView with our textContainer
        textView = UITextView(frame: .zero, textContainer: textContainer)
        super.init(coder: coder)
        setupTextKit()
        setupTextView()
    }
    
    // MARK: - Setup
    
    private func setupTextKit() {
        // TextKit stack is already connected in init
        // Configure text container
        textContainer.lineFragmentPadding = 5 // Standard UITextView padding
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        
    }
    
    private func setupTextView() {
        // Add text view as subview
        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Configure text view
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .label
        
        // Add proper text container insets for better cursor positioning
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        
        // Set default styling
        markdownTextStorage.setDefaultFont(textView.font ?? UIFont.systemFont(ofSize: 16))
        markdownTextStorage.setDefaultTextColor(textView.textColor ?? UIColor.label)
    }
    
    // MARK: - Public Methods
    
    public func insertText(_ text: String) {
        textView.insertText(text)
    }
    
    public func deleteBackward() {
        textView.deleteBackward()
    }
    
    public func scrollRangeToVisible(_ range: NSRange) {
        textView.scrollRangeToVisible(range)
    }
    
    public override func becomeFirstResponder() -> Bool {
        let result = textView.becomeFirstResponder()
        // Update cursor position when gaining focus
        markdownTextStorage.updateCursorPosition(textView.selectedRange.location)
        return result
    }
    
    public override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
    
    public override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }
    
}

// MARK: - UITextViewDelegate

extension MarkdownTextView: UITextViewDelegate {
    
    public func textViewDidChange(_ textView: UITextView) {
        // Update cursor position in text storage
        markdownTextStorage.updateCursorPosition(textView.selectedRange.location)
        delegate?.markdownTextViewDidChange(self)
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        // Update cursor position when selection changes (including cursor movement)
        markdownTextStorage.updateCursorPosition(textView.selectedRange.location)
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Handle markdown auto-completion and deletion
        if handleMarkdownAutoCompletion(range: range, replacementText: text) {
            return false // We handled it, don't let the text view process it
        }
        
        return delegate?.markdownTextView(self, shouldChangeTextIn: range, replacementText: text) ?? true
    }
    
    private func handleMarkdownAutoCompletion(range: NSRange, replacementText text: String) -> Bool {
        
        // Handle deletion
        if text.isEmpty && range.length == 1 {
            return handleMarkdownDeletion(at: range)
        }
        
        // Handle insertion
        if text == "*" {
            return handleAsteriskInsertion(at: range)
        }
        
        if text == "#" {
            return handleHashInsertion(at: range)
        }
        
        if text == "\n" {
            return handleReturnInsertion(at: range)
        }
        
        return false
    }
    
    private func handleAsteriskInsertion(at range: NSRange) -> Bool {
        let currentText = markdownTextStorage.string as NSString
        let insertionPoint = range.location
        
        // Check if we're typing a second asterisk (for bold)
        if insertionPoint > 0 && currentText.character(at: insertionPoint - 1) == 42 { // ASCII for *
            // We're typing the second *, DON'T insert it, just add closing **
            
            // Add closing ** at current position (don't insert the current *)
            let closingRange = NSRange(location: insertionPoint, length: 0)
            markdownTextStorage.replaceCharacters(in: closingRange, with: "**")
            
            // Position cursor between the ** pairs
            let newPosition = insertionPoint + 1
            textView.selectedRange = NSRange(location: newPosition, length: 0)
            return true
        }
        
        // Check if there's selected text to wrap
        if range.length > 0 {
            let selectedText = currentText.substring(with: range)
            let wrappedText = "*\(selectedText)*"
            markdownTextStorage.replaceCharacters(in: range, with: wrappedText)
            
            // Position cursor after the wrapped text
            let newPosition = range.location + wrappedText.count
            textView.selectedRange = NSRange(location: newPosition, length: 0)
            return true
        }
        
        // Insert single * and add closing *
        let asteriskPair = "**"
        markdownTextStorage.replaceCharacters(in: range, with: asteriskPair)
        
        // Position cursor between the asterisks
        let newPosition = insertionPoint + 1
        textView.selectedRange = NSRange(location: newPosition, length: 0)
        return true
    }
    
    private func handleHashInsertion(at range: NSRange) -> Bool {
        let currentText = markdownTextStorage.string as NSString
        let insertionPoint = range.location
        
        // Only auto-complete if we're at the beginning of a line
        if insertionPoint == 0 || currentText.character(at: insertionPoint - 1) == 10 { // newline
            // Check if there's selected text to wrap
            if range.length > 0 {
                let selectedText = currentText.substring(with: range)
                let headerText = "# \(selectedText)"
                markdownTextStorage.replaceCharacters(in: range, with: headerText)
                
                // Position cursor after the header
                let newPosition = range.location + headerText.count
                textView.selectedRange = NSRange(location: newPosition, length: 0)
                return true
            }
            
            // Just insert the # without auto-adding space
            let headerText = "#"
            markdownTextStorage.replaceCharacters(in: range, with: headerText)
            
            // Position cursor after the #
            let newPosition = insertionPoint + 1
            textView.selectedRange = NSRange(location: newPosition, length: 0)
            return true
        }
        
        return false
    }
    
    private func handleReturnInsertion(at range: NSRange) -> Bool {
        let currentText = markdownTextStorage.string as NSString
        let insertionPoint = range.location
        
        // Find the current line to check if we're in a list
        let lineRange = currentText.lineRange(for: NSRange(location: insertionPoint, length: 0))
        let lineText = currentText.substring(with: lineRange)
        
        // Check if current line is a list item
        if let listMatch = lineText.range(of: #"^([-\*\+])\s+(.*)$"#, options: .regularExpression) {
            let nsRange = NSRange(listMatch, in: lineText)
            let markerRange = lineText.range(of: #"^[-\*\+]"#, options: .regularExpression)!
            let marker = String(lineText[markerRange])
            let contentRange = lineText.range(of: #"(?<=^[-\*\+]\s).*$"#, options: .regularExpression)
            let content = contentRange != nil ? String(lineText[contentRange!]) : ""
            
            // If content is empty, this is a double-return to break out of list
            if content.trimmingCharacters(in: .whitespaces).isEmpty {
                // Remove the empty list item and break out
                let emptyListRange = NSRange(location: lineRange.location, length: lineRange.length - 1) // -1 to keep the newline
                markdownTextStorage.replaceCharacters(in: emptyListRange, with: "")
                
                // Position cursor at the now-empty line
                textView.selectedRange = NSRange(location: lineRange.location, length: 0)
                return true
            } else {
                // Continue the list with a new item
                let newListItem = "\n\(marker) "
                markdownTextStorage.replaceCharacters(in: range, with: newListItem)
                
                // Position cursor after the new marker
                let newPosition = insertionPoint + newListItem.count
                textView.selectedRange = NSRange(location: newPosition, length: 0)
                return true
            }
        }
        
        return false
    }
    
    private func handleMarkdownDeletion(at range: NSRange) -> Bool {
        let currentText = markdownTextStorage.string as NSString
        let deletionPoint = range.location
        
        guard deletionPoint < currentText.length else { return false }
        
        let charToDelete = currentText.character(at: deletionPoint)
        
        // Handle asterisk deletion
        if charToDelete == 42 { // ASCII for *
            return handleAsteriskDeletion(at: deletionPoint)
        }
        
        // Handle hash deletion  
        if charToDelete == 35 { // ASCII for #
            return handleHashDeletion(at: deletionPoint)
        }
        
        // Handle list marker deletion (-, +) - asterisk is handled above for bold
        if charToDelete == 45 || charToDelete == 43 { // ASCII for -, +
            return handleListMarkerDeletion(at: deletionPoint)
        }
        
        return false
    }
    
    private func handleAsteriskDeletion(at position: Int) -> Bool {
        let currentText = markdownTextStorage.string as NSString
        
        // Check for ** pair deletion
        if position > 0 && 
           position < currentText.length - 1 &&
           currentText.character(at: position - 1) == 42 && // Previous is *
           currentText.character(at: position + 1) == 42 {   // Next is *
            
            // Delete both asterisks
            let rangeToDelete = NSRange(location: position - 1, length: 3) // Delete *_* (including current char)
            markdownTextStorage.replaceCharacters(in: rangeToDelete, with: "")
            
            // Position cursor where the asterisks were
            textView.selectedRange = NSRange(location: position - 1, length: 0)
            return true
        }
        
        // Check for single * pair deletion
        if let matchingAsterisk = findMatchingAsterisk(for: position, in: currentText) {
            // Delete both asterisks
            let firstRange = NSRange(location: min(position, matchingAsterisk), length: 1)
            let secondRange = NSRange(location: max(position, matchingAsterisk), length: 1)
            
            // Delete the later one first to preserve indices
            markdownTextStorage.replaceCharacters(in: secondRange, with: "")
            markdownTextStorage.replaceCharacters(in: firstRange, with: "")
            
            // Position cursor at the first deletion point
            textView.selectedRange = NSRange(location: firstRange.location, length: 0)
            return true
        }
        
        return false
    }
    
    private func handleHashDeletion(at position: Int) -> Bool {
        let currentText = markdownTextStorage.string as NSString
        
        // Check if this is a header pattern (# at start of line followed by space)
        let isStartOfLine = position == 0 || currentText.character(at: position - 1) == 10
        let hasSpaceAfter = position < currentText.length - 1 && currentText.character(at: position + 1) == 32
        
        if isStartOfLine && hasSpaceAfter {
            // Delete # and the space after it
            let rangeToDelete = NSRange(location: position, length: 2)
            markdownTextStorage.replaceCharacters(in: rangeToDelete, with: "")
            
            // Position cursor where the # was
            textView.selectedRange = NSRange(location: position, length: 0)
            return true
        }
        
        return false
    }
    
    private func handleListMarkerDeletion(at position: Int) -> Bool {
        let currentText = markdownTextStorage.string as NSString
        
        // Check if this is a list marker pattern (-, + at start of line followed by space)
        let isStartOfLine = position == 0 || currentText.character(at: position - 1) == 10
        let hasSpaceAfter = position < currentText.length - 1 && currentText.character(at: position + 1) == 32
        
        if isStartOfLine && hasSpaceAfter {
            // Delete marker and the space after it
            let rangeToDelete = NSRange(location: position, length: 2)
            markdownTextStorage.replaceCharacters(in: rangeToDelete, with: "")
            
            // Position cursor where the marker was
            textView.selectedRange = NSRange(location: position, length: 0)
            return true
        }
        
        return false
    }
    
    private func findMatchingAsterisk(for position: Int, in text: NSString) -> Int? {
        // Simple matching logic - find the nearest unpaired asterisk
        // This is a simplified version; a full implementation would need proper parsing
        
        let searchRange = 50 // Search within 50 characters
        let startSearch = max(0, position - searchRange)
        let endSearch = min(text.length, position + searchRange)
        
        // Look backwards first
        for i in stride(from: position - 1, through: startSearch, by: -1) {
            if text.character(at: i) == 42 {
                return i
            }
        }
        
        // Look forwards
        for i in (position + 1)..<endSearch {
            if text.character(at: i) == 42 {
                return i
            }
        }
        
        return nil
    }
}

// MARK: - MarkdownTextStorage Extensions

extension MarkdownTextStorage {
    var font: UIFont? {
        if length == 0 { return nil }
        return attribute(.font, at: 0, effectiveRange: nil) as? UIFont
    }
    
    var textColor: UIColor? {
        if length == 0 { return nil }
        return attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
    }
}