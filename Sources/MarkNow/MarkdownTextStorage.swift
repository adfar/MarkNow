import UIKit
import Foundation

public class MarkdownTextStorage: NSTextStorage {
    private var _attributedString = NSMutableAttributedString()
    private let parser = MarkdownParser()
    
    private var defaultFont: UIFont = .systemFont(ofSize: 16)
    private var defaultTextColor: UIColor = .label
    
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
            // Hide the markdown syntax completely
            let startSyntaxRange = NSRange(location: range.location, length: 2)
            let endSyntaxRange = NSRange(location: range.location + range.length - 2, length: 2)
            
            hideTextRange(startSyntaxRange)
            hideTextRange(endSyntaxRange)
            
            // Bold the content
            let contentRange = NSRange(location: range.location + 2, length: range.length - 4)
            let boldFont = UIFont.boldSystemFont(ofSize: defaultFont.pointSize)
            addAttribute(.font, value: boldFont, range: contentRange)
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
            // Hide the markdown syntax completely
            let startSyntaxRange = NSRange(location: range.location, length: 1)
            let endSyntaxRange = NSRange(location: range.location + range.length - 1, length: 1)
            
            hideTextRange(startSyntaxRange)
            hideTextRange(endSyntaxRange)
            
            // Italicize the content
            let contentRange = NSRange(location: range.location + 1, length: range.length - 2)
            let italicFont = UIFont.italicSystemFont(ofSize: defaultFont.pointSize)
            addAttribute(.font, value: italicFont, range: contentRange)
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
            // Hide the markdown syntax (# symbols and space)
            let hashCount = level
            let syntaxRange = NSRange(location: range.location, length: hashCount + 1) // +1 for space
            hideTextRange(syntaxRange)
            
            // Apply header styling to content
            let contentRange = NSRange(location: range.location + hashCount + 1, length: range.length - hashCount - 1)
            let headerSize = max(defaultFont.pointSize + CGFloat(6 - level) * 2, defaultFont.pointSize)
            let headerFont = UIFont.boldSystemFont(ofSize: headerSize)
            
            addAttribute(.font, value: headerFont, range: contentRange)
            addAttribute(.foregroundColor, value: defaultTextColor, range: contentRange)
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
    
    private func hideTextRange(_ range: NSRange) {
        // Simple approach: just make text transparent while keeping normal font
        // This preserves cursor behavior but makes characters invisible
        addAttribute(.foregroundColor, value: UIColor.clear, range: range)
        addAttribute(.font, value: defaultFont, range: range)
    }
}