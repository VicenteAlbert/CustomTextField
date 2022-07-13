//
//  ViewController.swift
//  CustomTextView
//
//  Created by Vicentiu Petreaca on 01.07.2022.
//

import UIKit

protocol TextViewThemeProtocol {
    var placeholder: String { get }
    var errorMessage: String { get }
    var characterCountStringFormat: String { get }
    var placeholderColor: UIColor { get }
    var textColor: UIColor { get }
    var errorBorderColor: UIColor { get }
    var borderColor: UIColor { get }
    var borderSize: CGFloat { get }
    var font: UIFont { get }
}

extension TextViewThemeProtocol {
    var placeholder: String { "Spune cum am putea imbunatati aplicatia (optional)" }
    var placeholderColor: UIColor { .gray }
    var textColor: UIColor { .darkText }
    var errorMessage: String { "String invalid" }
    var characterCountStringFormat: String { "%d/%d caractere" }
    var errorBorderColor: UIColor { .red }
    var borderColor: UIColor { UIColor(0xEFF2F7) }
    var borderSize: CGFloat { 2 }
    var font: UIFont { .systemFont(ofSize: 12) }
}

class CustomTextView: UIView {
    private struct DefaultTheme: TextViewThemeProtocol {}
    
    private let textView = UITextView()
    private let errorLabel = UILabel()
    private let characterCountLabel = UILabel()
    var maxCharacters: Int = 300
    var isCharacterCountHidden: Bool = false {
        didSet {
            characterCountLabel.isHidden = isCharacterCountHidden
        }
    }
    
    var theme: TextViewThemeProtocol
    var textPredicate: ((String) -> Bool)? = nil
    override init(frame: CGRect) {
        theme = DefaultTheme()
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        theme = DefaultTheme()
        super.init(coder: coder)
        commonInit()
    }
    
    func set(theme: TextViewThemeProtocol) {
        self.theme = theme
        setUpColors()
    }
    
    private func commonInit() {
        textView.delegate = self
        setUpLayout()
    }

    private func setUpLayout() {
        let container = UIStackView(arrangedSubviews: [textView, errorLabel, characterCountLabel])
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .vertical
        container.distribution = .fill
        container.spacing = 6
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        textView.autocorrectionType = .no
        errorLabel.textColor = .red
        errorLabel.font = theme.font
        errorLabel.text = theme.errorMessage
        errorLabel.isHidden = true
        characterCountLabel.textColor = .lightGray
        characterCountLabel.font = .systemFont(ofSize: 12)
        characterCountLabel.textAlignment = .right
        updateCharacterCount(value: 0)
        setUpColors()
    }

    private func setUpColors() {
        textView.layer.borderColor = theme.borderColor.cgColor
        textView.layer.borderWidth = theme.borderSize
        textView.layer.cornerRadius = 10
        textView.font = .systemFont(ofSize: 17)
        textView.textContainerInset = .init(top: 14, left: 8, bottom: 14, right: 8)
        textView.textColor = theme.placeholderColor
        textView.text = theme.placeholder
    }

    private func updateCharacterCount(value: Int) {
        characterCountLabel.text = String(format: theme.characterCountStringFormat, value, maxCharacters)
    }
}

extension CustomTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == theme.placeholderColor {
            textView.text = nil
            textView.textColor = theme.textColor
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = theme.placeholder
            textView.textColor = theme.placeholderColor
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if window != nil {
            if textView.textColor == theme.placeholderColor {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Combine the textView text and the replacement text to create the updated text string
        let currentText: String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        let setNormalBorderColorAndHideError = {
            textView.layer.borderColor = self.theme.borderColor.cgColor
            self.errorLabel.isHidden = true
        }
        if let textPredicate = textPredicate {
            let isValid = textPredicate(updatedText)
            if isValid == false {
                errorLabel.isHidden = false
                textView.layer.borderColor = theme.errorBorderColor.cgColor
            } else {
                setNormalBorderColorAndHideError()
            }
        } else {
            setNormalBorderColorAndHideError()
        }
        // If updated text view will be empty, add the placeholder and set the cursor to the beginning of the text view
        if updatedText.isEmpty {
            textView.text = theme.placeholder
            textView.textColor = theme.placeholderColor
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            updateCharacterCount(value: 0)
        } else if textView.textColor == theme.placeholderColor && !text.isEmpty {
            // Else if the text view's placeholder is showing and the length of the replacement string is greater than 0,
            // set the text color to black then set its text to the replacement string
            textView.textColor = theme.textColor
            textView.text = text
            updateCharacterCount(value: text.count)
        } else {
            // For every other case, the text should change with the usual behavior...
            updateCharacterCount(value: updatedText.count)
            return true
        }
        // otherwise return false since the updates have already been made
        return false
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let text = CustomTextView()
        text.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(text)
        
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            text.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            text.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            text.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
}

extension UIColor {
    convenience init(_ rgbValue: Int) {
        self.init(
            red: CGFloat((Float((rgbValue & 0xff0000) >> 16)) / 255.0),
            green: CGFloat((Float((rgbValue & 0x00ff00) >> 8)) / 255.0),
            blue: CGFloat((Float((rgbValue & 0x0000ff) >> 0)) / 255.0),
            alpha: 1.0
        )
    }
}
