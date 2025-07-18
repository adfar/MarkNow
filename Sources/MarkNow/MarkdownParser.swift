import Foundation

public struct MarkdownToken {
    public let type: TokenType
    public let range: NSRange
    public let content: String
    public let isComplete: Bool
    
    public enum TokenType {
        case bold
        case italic
        case header(level: Int)
        case plain
        case incompleteBold
        case incompleteItalic
    }
}

public class MarkdownParser {
    private let boldPattern = #"\*\*(.*?)\*\*"#
    private let italicPattern = #"\*(.*?)\*"#
    private let headerPattern = #"^(#{1,6})\s+(.*)"#
    private let incompleteBoldPattern = #"\*\*(?!\*)"#
    private let incompleteItalicPattern = #"(?<!\*)\*(?!\*)"#
    
    private lazy var boldRegex = try! NSRegularExpression(pattern: boldPattern, options: [])
    private lazy var italicRegex = try! NSRegularExpression(pattern: italicPattern, options: [])
    private lazy var headerRegex = try! NSRegularExpression(pattern: headerPattern, options: [.anchorsMatchLines])
    private lazy var incompleteBoldRegex = try! NSRegularExpression(pattern: incompleteBoldPattern, options: [])
    private lazy var incompleteItalicRegex = try! NSRegularExpression(pattern: incompleteItalicPattern, options: [])
    
    public init() {}
    
    public func parseTokens(in text: String, range: NSRange? = nil) -> [MarkdownToken] {
        let searchRange = range ?? NSRange(location: 0, length: text.count)
        let nsText = text as NSString
        var tokens: [MarkdownToken] = []
        
        // Find headers first (they take precedence)
        let headerMatches = headerRegex.matches(in: text, options: [], range: searchRange)
        for match in headerMatches {
            let hashRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let hashCount = nsText.substring(with: hashRange).count
            let content = nsText.substring(with: contentRange)
            
            tokens.append(MarkdownToken(
                type: .header(level: hashCount),
                range: match.range,
                content: content,
                isComplete: true
            ))
        }
        
        // Find complete bold text (excluding areas already covered by headers)
        let boldMatches = boldRegex.matches(in: text, options: [], range: searchRange)
        for match in boldMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                let contentRange = match.range(at: 1)
                let content = nsText.substring(with: contentRange)
                
                tokens.append(MarkdownToken(
                    type: .bold,
                    range: match.range,
                    content: content,
                    isComplete: true
                ))
            }
        }
        
        // Find complete italic text (excluding areas already covered by headers and bold)
        let italicMatches = italicRegex.matches(in: text, options: [], range: searchRange)
        for match in italicMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                let contentRange = match.range(at: 1)
                let content = nsText.substring(with: contentRange)
                
                tokens.append(MarkdownToken(
                    type: .italic,
                    range: match.range,
                    content: content,
                    isComplete: true
                ))
            }
        }
        
        // Find incomplete bold markers (excluding areas already covered)
        let incompleteBoldMatches = incompleteBoldRegex.matches(in: text, options: [], range: searchRange)
        for match in incompleteBoldMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                tokens.append(MarkdownToken(
                    type: .incompleteBold,
                    range: match.range,
                    content: "**",
                    isComplete: false
                ))
            }
        }
        
        // Find incomplete italic markers (excluding areas already covered)
        let incompleteItalicMatches = incompleteItalicRegex.matches(in: text, options: [], range: searchRange)
        for match in incompleteItalicMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                tokens.append(MarkdownToken(
                    type: .incompleteItalic,
                    range: match.range,
                    content: "*",
                    isComplete: false
                ))
            }
        }
        
        return tokens.sorted { $0.range.location < $1.range.location }
    }
    
    public func parseParagraph(in text: String, at location: Int) -> [MarkdownToken] {
        let nsText = text as NSString
        let paragraphRange = nsText.paragraphRange(for: NSRange(location: location, length: 0))
        return parseTokens(in: text, range: paragraphRange)
    }
    
    private func isRangeOverlapping(_ range: NSRange, with tokens: [MarkdownToken]) -> Bool {
        return tokens.contains { token in
            NSIntersectionRange(range, token.range).length > 0
        }
    }
}