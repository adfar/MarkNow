import UIKit
import Foundation

public class MarkdownTextStorage: NSTextStorage {
    private var _attributedString = NSMutableAttributedString()
    private let parser = MarkdownParser()
    
    private var defaultFont: UIFont = .systemFont(ofSize: 16)
    private var defaultTextColor: UIColor = .label
    private var currentCursorPosition: Int = 0
    
    public override var string: String {
        return _attributedString.string
    }
    
    public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        return _attributedString.attributes(at: location, effectiveRange: range)
    }
    
    public override func replaceCharacters(in range: NSRange, with str: String) {
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
        case .incompleteBold:
            applyIncompleteBoldFormatting(for: token)
        case .incompleteItalic:
            applyIncompleteItalicFormatting(for: token)
        case .incompleteHeader(let level):
            applyIncompleteHeaderFormatting(for: token, level: level)
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
    
    public func setDefaultFont(_ font: UIFont) {
        defaultFont = font
    }
    
    public func setDefaultTextColor(_ color: UIColor) {
        defaultTextColor = color
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
}