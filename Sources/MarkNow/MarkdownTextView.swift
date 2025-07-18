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
            // Update cursor position after setting text
            markdownTextStorage.updateCursorPosition(textView.selectedRange.location)
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
        textContainer.lineFragmentPadding = 0
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
        return delegate?.markdownTextView(self, shouldChangeTextIn: range, replacementText: text) ?? true
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