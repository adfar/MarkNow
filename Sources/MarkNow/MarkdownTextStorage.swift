import UIKit
import Foundation

public class MarkdownTextStorage: NSTextStorage {
    private var _attributedString = NSMutableAttributedString()
    private let parser = MarkdownParser()
    
    private var defaultFont: UIFont = .systemFont(ofSize: 16)
    private var defaultTextColor: UIColor = .label
    private var currentCursorPosition: Int = 0
    
    // Text state management for bullet point replacement
    private var originalText: String = ""
    private var isInReplacementMode = false
    private var activeReplacements: [NSRange: String] = [:] // Maps ranges to original text
    
    public override var string: String {
        return _attributedString.string
    }
    
    public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        return _attributedString.attributes(at: location, effectiveRange: range)
    }
    
    public override func replaceCharacters(in range: NSRange, with str: String) {
        // Don't update original text if we're in replacement mode (internal bullet replacement)
        if !isInReplacementMode {
            // Clear active replacements for significant text changes to handle undo/redo
            if str.count != range.length {
                activeReplacements.removeAll()
            }
            
            // Update original text to match the change
            let nsOriginal = NSMutableString(string: originalText)
            if range.location <= nsOriginal.length && range.location + range.length <= nsOriginal.length {
                nsOriginal.replaceCharacters(in: range, with: str)
                originalText = nsOriginal as String
            }
        }
        
        beginEditing()
        _attributedString.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        endEditing()
    }
    
    public override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        _attributedString.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    public override func processEditing() {
        performMarkdownFormatting()
        super.processEditing()
    }
    
    private func performMarkdownFormatting() {
        // Don't format during replacement operations to prevent infinite loops
        guard !isInReplacementMode else { return }
        
        let range = editedRange
        if range.location == NSNotFound {
            return
        }
        
        // Reset attributes to default for the edited range
        removeAttribute(.font, range: range)
        removeAttribute(.foregroundColor, range: range)
        
        // Apply default attributes
        addAttribute(.font, value: defaultFont, range: range)
        addAttribute(.foregroundColor, value: defaultTextColor, range: range)
        
        // Parse and format the affected paragraph
        let paragraphRange = (string as NSString).paragraphRange(for: range)
        let tokens = parser.parseTokens(in: string, range: paragraphRange)
        
        for token in tokens {
            applyFormatting(for: token)
        }
    }
    
    private func applyFormatting(for token: MarkdownToken) {
        switch token.type {
        case .bold:
            applyBoldFormatting(for: token)
        case .italic:
            applyItalicFormatting(for: token)
        case .header(let level):
            applyHeaderFormatting(for: token, level: level)
        case .list:
            applyListFormatting(for: token)
        case .inlineCode:
            applyInlineCodeFormatting(for: token)
        case .codeBlock:
            applyCodeBlockFormatting(for: token)
        case .incompleteBold:
            applyIncompleteBoldFormatting(for: token)
        case .incompleteItalic:
            applyIncompleteItalicFormatting(for: token)
        case .incompleteHeader(let level):
            applyIncompleteHeaderFormatting(for: token, level: level)
        case .incompleteList:
            applyIncompleteListFormatting(for: token)
        case .incompleteInlineCode:
            applyIncompleteInlineCodeFormatting(for: token)
        case .incompleteCodeBlock:
            applyIncompleteCodeBlockFormatting(for: token)
        case .plain:
            break
        }
    }
    
    private func applyBoldFormatting(for token: MarkdownToken) {
        let range = token.range
        
        if token.isComplete {
            let contentRange = NSRange(location: range.location + 2, length: range.length - 4)
            let boldFont = UIFont.boldSystemFont(ofSize: defaultFont.pointSize)
            addAttribute(.font, value: boldFont, range: contentRange)
            
            // Only hide symbols if cursor is NOT in this block
            if !isTokenInCurrentBlock(token) {
                let startSyntaxRange = NSRange(location: range.location, length: 2)
                let endSyntaxRange = NSRange(location: range.location + range.length - 2, length: 2)
                
                hideTextRange(startSyntaxRange)
                hideTextRange(endSyntaxRange)
            }
        }
    }
    
    private func applyIncompleteBoldFormatting(for token: MarkdownToken) {
        let range = token.range
        
        // Show incomplete syntax dimmed
        addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
    }
    
    private func applyItalicFormatting(for token: MarkdownToken) {
        let range = token.range
        
        if token.isComplete {
            let contentRange = NSRange(location: range.location + 1, length: range.length - 2)
            let italicFont = UIFont.italicSystemFont(ofSize: defaultFont.pointSize)
            addAttribute(.font, value: italicFont, range: contentRange)
            
            // Only hide symbols if cursor is NOT in this block
            if !isTokenInCurrentBlock(token) {
                let startSyntaxRange = NSRange(location: range.location, length: 1)
                let endSyntaxRange = NSRange(location: range.location + range.length - 1, length: 1)
                
                hideTextRange(startSyntaxRange)
                hideTextRange(endSyntaxRange)
            }
        }
    }
    
    private func applyIncompleteItalicFormatting(for token: MarkdownToken) {
        let range = token.range
        
        // Show incomplete syntax dimmed
        addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
    }
    
    private func applyHeaderFormatting(for token: MarkdownToken, level: Int) {
        let range = token.range
        
        if token.isComplete {
            let hashCount = level
            let contentRange = NSRange(location: range.location + hashCount + 1, length: range.length - hashCount - 1)
            let headerSize = max(defaultFont.pointSize + CGFloat(6 - level) * 2, defaultFont.pointSize)
            let headerFont = UIFont.boldSystemFont(ofSize: headerSize)
            
            addAttribute(.font, value: headerFont, range: contentRange)
            addAttribute(.foregroundColor, value: defaultTextColor, range: contentRange)
            
            // Only hide symbols if cursor is NOT in this block
            if !isTokenInCurrentBlock(token) {
                let syntaxRange = NSRange(location: range.location, length: hashCount + 1) // +1 for space
                hideTextRange(syntaxRange)
            }
        }
    }
    
    private func applyIncompleteHeaderFormatting(for token: MarkdownToken, level: Int) {
        let range = token.range
        
        // Show incomplete syntax dimmed
        addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
    }
    
    private func applyListFormatting(for token: MarkdownToken) {
        let range = token.range
        
        if token.isComplete {
            // Find the content after the marker (- item, * item, + item)
            let markerRange = NSRange(location: range.location, length: 2) // marker + space
            let contentRange = NSRange(location: range.location + 2, length: range.length - 2)
            
            // Apply formatting to the content
            addAttribute(.font, value: defaultFont, range: contentRange)
            addAttribute(.foregroundColor, value: defaultTextColor, range: contentRange)
            
            let cursorInBlock = isTokenInCurrentBlock(token)
            
            // Handle bullet replacement based on cursor position
            if !cursorInBlock {
                // Replace marker with bullet if not already done
                replaceBulletMarker(at: markerRange)
            } else {
                // Restore original marker if cursor is in block
                restoreOriginalMarker(at: markerRange)
            }
        }
    }
    
    private func applyIncompleteListFormatting(for token: MarkdownToken) {
        let range = token.range
        
        // Show incomplete syntax dimmed
        addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
    }
    
    private func applyInlineCodeFormatting(for token: MarkdownToken) {
        let range = token.range
        
        if token.isComplete {
            let contentRange = NSRange(location: range.location + 1, length: range.length - 2)
            let codeFont = UIFont(name: "Menlo", size: defaultFont.pointSize) ?? UIFont.monospacedSystemFont(ofSize: defaultFont.pointSize, weight: .regular)
            
            addAttribute(.font, value: codeFont, range: contentRange)
            addAttribute(.foregroundColor, value: UIColor.systemRed, range: contentRange)
            addAttribute(.backgroundColor, value: UIColor.systemGray6, range: contentRange)
            
            // Only hide backticks if cursor is NOT in this block
            if !isTokenInCurrentBlock(token) {
                let startBacktickRange = NSRange(location: range.location, length: 1)
                let endBacktickRange = NSRange(location: range.location + range.length - 1, length: 1)
                
                hideTextRange(startBacktickRange)
                hideTextRange(endBacktickRange)
            }
        }
    }
    
    private func applyCodeBlockFormatting(for token: MarkdownToken) {
        let range = token.range
        
        if token.isComplete {
            let contentRange = NSRange(location: range.location + 3, length: range.length - 6)
            let codeFont = UIFont(name: "Menlo", size: defaultFont.pointSize) ?? UIFont.monospacedSystemFont(ofSize: defaultFont.pointSize, weight: .regular)
            
            addAttribute(.font, value: codeFont, range: contentRange)
            addAttribute(.foregroundColor, value: UIColor.systemBlue, range: contentRange)
            addAttribute(.backgroundColor, value: UIColor.systemGray6, range: contentRange)
            
            // Only hide triple backticks if cursor is NOT in this block
            if !isTokenInCurrentBlock(token) {
                let startBackticksRange = NSRange(location: range.location, length: 3)
                let endBackticksRange = NSRange(location: range.location + range.length - 3, length: 3)
                
                hideTextRange(startBackticksRange)
                hideTextRange(endBackticksRange)
            }
        }
    }
    
    private func applyIncompleteInlineCodeFormatting(for token: MarkdownToken) {
        let range = token.range
        
        // Show incomplete syntax dimmed
        addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
    }
    
    private func applyIncompleteCodeBlockFormatting(for token: MarkdownToken) {
        let range = token.range
        
        // Show incomplete syntax dimmed
        addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
    }
    
    public func setDefaultFont(_ font: UIFont) {
        defaultFont = font
    }
    
    public func setDefaultTextColor(_ color: UIColor) {
        defaultTextColor = color
    }
    
    public func setInitialText(_ text: String) {
        originalText = text
        activeReplacements.removeAll()
    }
    
    public func getOriginalMarkerAt(_ position: Int) -> String? {
        // Check if the position is within bounds of original text
        guard position < originalText.count else { return nil }
        
        // Get the character at this position in original text
        let originalChar = (originalText as NSString).substring(with: NSRange(location: position, length: 1))
        
        // Return if it's a valid list marker
        if originalChar == "-" || originalChar == "*" || originalChar == "+" {
            return originalChar
        }
        
        return nil
    }
    
    public func updateCursorPosition(_ position: Int) {
        
        // Bounds check the position
        let safePosition = max(0, min(position, length))
        let oldPosition = currentCursorPosition
        currentCursorPosition = safePosition
        
        // Only proceed if we have text
        guard length > 0 else { return }
        
        // Reformat the entire document for now to ensure it works
        let fullRange = NSRange(location: 0, length: length)
        reformatParagraph(at: fullRange)
    }
    
    private func reformatParagraph(at range: NSRange) {
        // Reset attributes for the paragraph
        removeAttribute(.font, range: range)
        removeAttribute(.foregroundColor, range: range)
        
        // Apply default attributes
        addAttribute(.font, value: defaultFont, range: range)
        addAttribute(.foregroundColor, value: defaultTextColor, range: range)
        
        // Parse and format the paragraph
        let tokens = parser.parseTokens(in: string, range: range)
        for token in tokens {
            applyFormatting(for: token)
        }
    }
    
    private func isTokenInCurrentBlock(_ token: MarkdownToken) -> Bool {
        // Bounds check the cursor position
        guard length > 0 else { return false }
        let safeCursorPosition = max(0, min(currentCursorPosition, length))
        
        // Check if cursor is within the token's range, but exclude the very start position
        // Being positioned at the start of a block shouldn't count as being "in" the block
        let isInTokenRange = NSLocationInRange(safeCursorPosition, token.range) && 
                           safeCursorPosition > token.range.location
        
        return isInTokenRange
    }
    
    private func lineNumber(for position: Int) -> Int {
        let nsString = string as NSString
        var lineNumber = 0
        var index = 0
        
        while index < position && index < nsString.length {
            if nsString.character(at: index) == 10 { // ASCII newline character
                lineNumber += 1
            }
            index += 1
        }
        
        return lineNumber
    }
    
    private func hideTextRange(_ range: NSRange) {
        // Use font size 0.01 to make characters nearly invisible
        // This preserves text but minimizes visual impact
        addAttribute(.foregroundColor, value: UIColor.clear, range: range)
        addAttribute(.font, value: UIFont.systemFont(ofSize: 0.01), range: range)
    }
    
    private func replaceBulletMarker(at range: NSRange) {
        // Store current cursor position to preserve it
        let savedCursorPosition = currentCursorPosition
        
        // Check if this range already has a bullet by checking the actual character
        let currentChar = (_attributedString.string as NSString).substring(with: NSRange(location: range.location, length: 1))
        if currentChar == "•" {
            return // Already has bullet
        }
        
        // Store the original marker text using location as key (more stable than range)
        let originalMarker = (_attributedString.string as NSString).substring(with: range)
        activeReplacements[range] = originalMarker
        
        // Replace with bullet
        isInReplacementMode = true
        let bulletRange = NSRange(location: range.location, length: 1) // Just the marker char
        
        // Replace marker with bullet, keep the space
        _attributedString.replaceCharacters(in: bulletRange, with: "•")
        
        // Apply proper formatting to the bullet
        addAttribute(.font, value: defaultFont, range: bulletRange)
        addAttribute(.foregroundColor, value: defaultTextColor, range: bulletRange)
        
        // Ensure space after bullet also has proper formatting
        let spaceRange = NSRange(location: range.location + 1, length: 1)
        if spaceRange.location < _attributedString.length {
            addAttribute(.font, value: defaultFont, range: spaceRange)
            addAttribute(.foregroundColor, value: defaultTextColor, range: spaceRange)
        }
        
        // Restore cursor position if it was affected
        if savedCursorPosition >= range.location {
            currentCursorPosition = savedCursorPosition
        }
        
        isInReplacementMode = false
    }
    
    private func restoreOriginalMarker(at range: NSRange) {
        // Store current cursor position to preserve it
        let savedCursorPosition = currentCursorPosition
        
        // Check if this actually has a bullet to restore
        let currentChar = (_attributedString.string as NSString).substring(with: NSRange(location: range.location, length: 1))
        if currentChar != "•" {
            return // Not a bullet, nothing to restore
        }
        
        // Find the original marker by checking what it should be from original text
        let originalRange = NSRange(location: range.location, length: 2)
        if originalRange.location + originalRange.length <= originalText.count {
            let originalMarker = (originalText as NSString).substring(with: originalRange)
            
            // Restore the original marker
            isInReplacementMode = true
            _attributedString.replaceCharacters(in: range, with: originalMarker)
            
            // Restore cursor position if it was affected
            if savedCursorPosition >= range.location {
                currentCursorPosition = savedCursorPosition + (originalMarker.count - range.length)
            }
            
            isInReplacementMode = false
        }
    }
    
    private func replaceTextRangeVisually(_ range: NSRange, with replacement: String) {
        // Hide the original text
        hideTextRange(range)
        
        // For now, we'll just use paragraph styling to create bullet effect
        // Future enhancement: could use NSTextAttachment for actual bullet replacement
    }
}