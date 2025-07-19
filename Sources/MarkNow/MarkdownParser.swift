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
        case list
        case inlineCode
        case codeBlock
        case plain
        case incompleteBold
        case incompleteItalic
        case incompleteHeader(level: Int)
        case incompleteList
        case incompleteInlineCode
        case incompleteCodeBlock
    }
}

public class MarkdownParser {
    private let boldPattern = #"\*\*(.*?)\*\*"#
    private let italicPattern = #"\*(.*?)\*"#
    private let headerPattern = #"^(#{1,6})\s+(.+)"#
    private let listPattern = #"^([-\*\+])\s+(.+)"#
    private let inlineCodePattern = #"`(.*?)`"#
    private let codeBlockPattern = #"```(.*?)```"#
    private let incompleteHeaderPattern = #"^(#{1,6})\s*$"#
    private let incompleteListPattern = #"^([-\*\+])\s*$"#
    private let incompleteBoldPattern = #"\*\*(?!\*)"#
    private let incompleteItalicPattern = #"(?<!\*)\*(?!\*)"#
    private let incompleteInlineCodePattern = #"`(?!`)"#
    private let incompleteCodeBlockPattern = #"```(?!`)"#
    
    private lazy var boldRegex = try! NSRegularExpression(pattern: boldPattern, options: [])
    private lazy var italicRegex = try! NSRegularExpression(pattern: italicPattern, options: [])
    private lazy var headerRegex = try! NSRegularExpression(pattern: headerPattern, options: [.anchorsMatchLines])
    private lazy var listRegex = try! NSRegularExpression(pattern: listPattern, options: [.anchorsMatchLines])
    private lazy var inlineCodeRegex = try! NSRegularExpression(pattern: inlineCodePattern, options: [])
    private lazy var codeBlockRegex = try! NSRegularExpression(pattern: codeBlockPattern, options: [.dotMatchesLineSeparators])
    private lazy var incompleteHeaderRegex = try! NSRegularExpression(pattern: incompleteHeaderPattern, options: [.anchorsMatchLines])
    private lazy var incompleteListRegex = try! NSRegularExpression(pattern: incompleteListPattern, options: [.anchorsMatchLines])
    private lazy var incompleteBoldRegex = try! NSRegularExpression(pattern: incompleteBoldPattern, options: [])
    private lazy var incompleteItalicRegex = try! NSRegularExpression(pattern: incompleteItalicPattern, options: [])
    private lazy var incompleteInlineCodeRegex = try! NSRegularExpression(pattern: incompleteInlineCodePattern, options: [])
    private lazy var incompleteCodeBlockRegex = try! NSRegularExpression(pattern: incompleteCodeBlockPattern, options: [])
    
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
        
        // Find lists (they take precedence after headers)
        let listMatches = listRegex.matches(in: text, options: [], range: searchRange)
        for match in listMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                let markerRange = match.range(at: 1)
                let contentRange = match.range(at: 2)
                let marker = nsText.substring(with: markerRange)
                let content = nsText.substring(with: contentRange)
                
                tokens.append(MarkdownToken(
                    type: .list,
                    range: match.range,
                    content: content,
                    isComplete: true
                ))
            }
        }
        
        // Find complete bold text (excluding areas already covered by headers and lists)
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
        
        // Find complete inline code (excluding areas already covered)
        let inlineCodeMatches = inlineCodeRegex.matches(in: text, options: [], range: searchRange)
        for match in inlineCodeMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                let contentRange = match.range(at: 1)
                let content = nsText.substring(with: contentRange)
                
                tokens.append(MarkdownToken(
                    type: .inlineCode,
                    range: match.range,
                    content: content,
                    isComplete: true
                ))
            }
        }
        
        // Find complete code blocks (excluding areas already covered)
        let codeBlockMatches = codeBlockRegex.matches(in: text, options: [], range: searchRange)
        for match in codeBlockMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                let contentRange = match.range(at: 1)
                let content = nsText.substring(with: contentRange)
                
                tokens.append(MarkdownToken(
                    type: .codeBlock,
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
        
        // Find incomplete headers (excluding areas already covered)
        let incompleteHeaderMatches = incompleteHeaderRegex.matches(in: text, options: [], range: searchRange)
        for match in incompleteHeaderMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                let hashRange = match.range(at: 1)
                let hashCount = nsText.substring(with: hashRange).count
                
                tokens.append(MarkdownToken(
                    type: .incompleteHeader(level: hashCount),
                    range: match.range,
                    content: nsText.substring(with: hashRange),
                    isComplete: false
                ))
            }
        }
        
        // Find incomplete lists (excluding areas already covered)
        let incompleteListMatches = incompleteListRegex.matches(in: text, options: [], range: searchRange)
        for match in incompleteListMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                let markerRange = match.range(at: 1)
                let marker = nsText.substring(with: markerRange)
                
                tokens.append(MarkdownToken(
                    type: .incompleteList,
                    range: match.range,
                    content: marker,
                    isComplete: false
                ))
            }
        }
        
        // Find incomplete inline code markers (excluding areas already covered)
        let incompleteInlineCodeMatches = incompleteInlineCodeRegex.matches(in: text, options: [], range: searchRange)
        for match in incompleteInlineCodeMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                tokens.append(MarkdownToken(
                    type: .incompleteInlineCode,
                    range: match.range,
                    content: "`",
                    isComplete: false
                ))
            }
        }
        
        // Find incomplete code block markers (excluding areas already covered)
        let incompleteCodeBlockMatches = incompleteCodeBlockRegex.matches(in: text, options: [], range: searchRange)
        for match in incompleteCodeBlockMatches {
            if !isRangeOverlapping(match.range, with: tokens) {
                tokens.append(MarkdownToken(
                    type: .incompleteCodeBlock,
                    range: match.range,
                    content: "```",
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