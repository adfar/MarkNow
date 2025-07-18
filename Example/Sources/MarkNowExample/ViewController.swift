import UIKit
import MarkNow

class ViewController: UIViewController {
    
    private let markdownTextView = MarkdownTextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "MarkNow Example"
        view.backgroundColor = .systemBackground
        
        setupMarkdownTextView()
        setupSampleText()
    }
    
    private func setupMarkdownTextView() {
        markdownTextView.delegate = self
        markdownTextView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(markdownTextView)
        
        NSLayoutConstraint.activate([
            markdownTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            markdownTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            markdownTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            markdownTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        markdownTextView.font = UIFont.systemFont(ofSize: 16)
        markdownTextView.textColor = .label
    }
    
    private func setupSampleText() {
        let sampleText = """
        # MarkNow Example
        
        This is a **bold** text example.
        
        You can also use *italic* text.
        
        ## Features
        
        - Real-time markdown rendering
        - **Bold** and *italic* support
        - Header formatting
        - TextKit-based architecture
        
        ### Try it out!
        
        Start typing some markdown:
        - Use **double asterisks** for bold
        - Use *single asterisks* for italic
        - Use # for headers
        
        The formatting will appear as you type!
        """
        
        markdownTextView.text = sampleText
    }
}

extension ViewController: MarkdownTextViewDelegate {
    func markdownTextViewDidChange(_ textView: MarkdownTextView) {
        // Handle text changes if needed
    }
    
    func markdownTextView(_ textView: MarkdownTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
}