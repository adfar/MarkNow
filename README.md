# MarkNow

A Swift Package for creating a custom UITextView that renders Markdown formatting live as the user types, similar to Bear or Obsidian.

## Features

- **Real-time Markdown rendering** - See formatting as you type
- **TextKit-based architecture** - Uses NSTextStorage subclass for efficient text handling
- **Performance optimized** - Only parses affected paragraphs on each keystroke
- **Clean API** - Similar to UITextView with delegate pattern
- **Extensible** - Easy to add more markdown features

## Supported Markdown

- **Bold text** using `**text**`
- *Italic text* using `*text*`
- Headers using `# H1`, `## H2`, etc.

## Installation

### Swift Package Manager

Add this to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/MarkNow", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select your target

## Usage

### Basic Usage

```swift
import MarkNow

class ViewController: UIViewController {
    private let markdownTextView = MarkdownTextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the text view
        markdownTextView.delegate = self
        markdownTextView.text = "# Hello **World**!"
        
        // Add to view hierarchy
        view.addSubview(markdownTextView)
        // ... setup constraints
    }
}

extension ViewController: MarkdownTextViewDelegate {
    func markdownTextViewDidChange(_ textView: MarkdownTextView) {
        // Handle text changes
    }
    
    func markdownTextView(_ textView: MarkdownTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
}
```

### Customization

```swift
// Customize font and colors
markdownTextView.font = UIFont.systemFont(ofSize: 18)
markdownTextView.textColor = .label

// Access the underlying text storage for advanced customization
let textStorage = markdownTextView.textStorage
textStorage.setDefaultFont(UIFont.systemFont(ofSize: 16))
textStorage.setDefaultTextColor(.label)
```

## Architecture

### Core Components

- **MarkdownTextView**: The main view that contains the TextKit stack
- **MarkdownTextStorage**: NSTextStorage subclass that handles text formatting
- **MarkdownParser**: Parses markdown tokens from text
- **MarkdownToken**: Represents a markdown formatting token

### Performance

The library is designed for performance:
- Only parses the affected paragraph on each keystroke
- Uses efficient NSTextStorage for text handling
- Minimal regex operations
- Handles documents up to ~10,000 words efficiently

## Example App

Run the example app to see MarkNow in action:

```bash
cd Example
swift run # This won't work with UIKit - use Xcode instead
```

Or open the Example folder in Xcode and run it on iOS Simulator.

## Development

### Building the Package

Since this package uses UIKit, you'll need to build it with Xcode or use an iOS target:

```bash
# This will fail because UIKit isn't available in command line Swift
swift build

# Instead, open in Xcode or use with an iOS project
```

### Testing

Run tests with:

```bash
swift test # May need iOS simulator for UIKit tests
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Roadmap

- [ ] More markdown features (links, images, lists)
- [ ] Syntax highlighting for code blocks
- [ ] Table support
- [ ] Plugin architecture for custom formatting
- [ ] Performance improvements for very large documents
- [ ] Accessibility enhancements