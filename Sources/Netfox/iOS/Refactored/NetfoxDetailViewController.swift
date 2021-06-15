//
//  NetfoxDetailViewController.swift
//  
//
//  Created by Clément Nonn on 15/06/2021.
//

#if os(iOS)

import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

final class SimpleTextActivity: NSObject, UIActivityItemSource {
    let content: String
    let requestUrl: String

    init(content: String, requestUrl: String) {
        self.content = content
        self.requestUrl = requestUrl
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return "placeholder"
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return content
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "netfox log - \(requestUrl)"
    }
}

final class LogFileActivity: NSObject, UIActivityItemSource {
    let content: URL

    init(content: URL) {
        self.content = content
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return URL(fileURLWithPath: "")
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return content
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "netfox log - \(content.lastPathComponent)"
    }
}

public final class NetfoxDetailViewController: UIViewController {
    enum DetailsView {
        case info
        case request
        case response
    }

    var selectedModel: NFXHTTPModel = NFXHTTPModel()

    lazy var infoButton = createHeaderButton("Info", selector: #selector(NetfoxDetailViewController.infoButtonPressed))
    lazy var requestButton = createHeaderButton("Request", selector: #selector(NetfoxDetailViewController.requestButtonPressed))
    lazy var responseButton = createHeaderButton("Response", selector: #selector(NetfoxDetailViewController.responseButtonPressed))

    private var copyAlert: UIAlertController?

    lazy var infoView = createDetailsView(getInfoStringFromObject(self.selectedModel), forView: .info)
    lazy var requestView = createDetailsView(getRequestStringFromObject(self.selectedModel), forView: .request)
    lazy var responseView = createDetailsView(getResponseStringFromObject(self.selectedModel), forView: .response)

    private lazy var headerButtons: [UIButton] = [self.infoButton, self.requestButton, self.responseButton]

    private lazy var infoViews: [UIScrollView] = [
        createDetailsView(getInfoStringFromObject(self.selectedModel), forView: .info),
        createDetailsView(getRequestStringFromObject(self.selectedModel), forView: .request),
        createDetailsView(getResponseStringFromObject(self.selectedModel), forView: .response)
    ]

    var sharedContent: String?

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Details"

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(NetfoxDetailViewController.actionButtonPressed(_:))
        )

        self.view.backgroundColor = .white

        // Header buttons
        headerButtons.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        let stackButtons = UIStackView(arrangedSubviews: headerButtons)
        stackButtons.distribution = .fillEqually
        stackButtons.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackButtons)
        NSLayoutConstraint.activate([
            stackButtons.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackButtons.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackButtons.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackButtons.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Info views
        self.infoViews.enumerated().forEach { index, view in
            view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(view)

            view.topAnchor.constraint(equalTo: stackButtons.bottomAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }

        infoButtonPressed()
    }

    // Header

    private func createHeaderButton(_ title: String, selector: Selector) -> UIButton {
        let tempButton = UIButton()
        tempButton.backgroundColor = UIColor.lightGray
        tempButton.setTitle(title, for: .normal)
        tempButton.setTitleColor(UIColor.init(netHex: 0x6d6d6d), for: .normal)
        tempButton.setTitleColor(UIColor.NFXOrangeColor(), for: .selected)
        tempButton.setTitleColor(UIColor.NFXOrangeColor(), for: .highlighted)
        tempButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        tempButton.addTarget(self, action: selector, for: .touchUpInside)
        return tempButton
    }

    @objc func infoButtonPressed() {
        buttonPressed(self.infoButton)
    }

    @objc func requestButtonPressed() {
        buttonPressed(self.requestButton)
    }

    @objc func responseButtonPressed() {
        buttonPressed(self.responseButton)
    }

    func buttonPressed(_ sender: UIButton) {
        guard let selectedButtonIdx = self.headerButtons.firstIndex(of: sender) else {
            return
        }
        for i in 0..<infoViews.count {
            infoViews[i].isHidden = selectedButtonIdx != i
            headerButtons[i].isSelected = selectedButtonIdx == i
        }
    }

    // Details

    func createDetailsView(_ content: NSAttributedString, forView: DetailsView) -> UIScrollView {
        let scrollView = UIScrollView()
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true

        let textView = UITextView()
        textView.font = UIFont.NFXFont(size: 13)
        textView.textColor = UIColor.NFXGray44Color()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.attributedText = content
        textView.delegate = self
        contentView.addSubview(textView)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        textView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true

        let lpgr = UILongPressGestureRecognizer(
            target: self,
            action: #selector(NetfoxDetailViewController.copyLabel)
        )
        textView.addGestureRecognizer(lpgr)

        if self.selectedModel.requestBodyLength > 1024 {
            let moreButton = UIButton()
            moreButton.backgroundColor = UIColor.NFXGray44Color()
            switch forView {
            case DetailsView.request:
                moreButton.setTitle("Show request body", for: .normal)
                moreButton.addTarget(self, action: #selector(NetfoxDetailViewController.requestBodyButtonPressed), for: .touchUpInside)
            case DetailsView.response:
                moreButton.setTitle("Show response body", for: .normal)
                moreButton.addTarget(self, action: #selector(NetfoxDetailViewController.responseBodyButtonPressed), for: .touchUpInside)
            default:
                break
            }
            contentView.addSubview(moreButton)

            moreButton.translatesAutoresizingMaskIntoConstraints = false
            moreButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
            moreButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
            moreButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            moreButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 10).isActive = true
            moreButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true

//            scrollView.contentSize = CGSize(
//                width: textView.frame.width,
//                height: moreButton.frame.maxY + 16
//            )
        } else {
            textView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true

//            scrollView.contentSize = CGSize(
//                width: textView.frame.width,
//                height: textView.frame.maxY + 16
//            )
        }

        return scrollView
    }

    @objc fileprivate func copyLabel(lpgr: UILongPressGestureRecognizer) {
        guard let text = (lpgr.view as? UILabel)?.text,
              copyAlert == nil else { return }

        UIPasteboard.general.string = text

        let alert = UIAlertController(title: "Text Copied!", message: nil, preferredStyle: .alert)
        copyAlert = alert

        self.present(alert, animated: true) { [weak self] in
            guard let self = self else { return }

            Timer.scheduledTimer(
                timeInterval: 0.45,
                target: self,
                selector: #selector(NetfoxDetailViewController.dismissCopyAlert),
                userInfo: nil,
                repeats: false
            )
        }
    }

    @objc fileprivate func dismissCopyAlert() {
        copyAlert?.dismiss(animated: true) { [weak self] in self?.copyAlert = nil }
    }

    @objc func responseBodyButtonPressed() {
        showBody(type: .response)
    }

    @objc func requestBodyButtonPressed() {
        showBody(type: .request)
    }

    func showBody(type: NFXBodyType) {
        let bodyDetailsController: NFXGenericBodyDetailsController

        if self.selectedModel.shortType as String == HTTPModelShortType.IMAGE.rawValue {
            bodyDetailsController = NFXImageBodyDetailsController()
        } else {
            bodyDetailsController = NFXRawBodyDetailsController()
        }
        bodyDetailsController.selectedModel(self.selectedModel)
        bodyDetailsController.bodyType = type

        self.navigationController?.pushViewController(bodyDetailsController, animated: true)
    }

    // Sharing

    @objc func actionButtonPressed(_ sender: UIBarButtonItem) {
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheetController.addAction(cancelAction)

        let simpleLog = UIAlertAction(title: "Simple log", style: .default) { [unowned self] _ in
            self.shareLog(full: false, sender: sender)
        }
        actionSheetController.addAction(simpleLog)

        let fullLogAction = UIAlertAction(title: "Full log", style: .default) { [unowned self] _ in
            self.shareLog(full: true, sender: sender)
        }
        actionSheetController.addAction(fullLogAction)

        if let reqCurl = self.selectedModel.requestCurl {
            let curlAction = UIAlertAction(title: "Export request as curl", style: .default) { [unowned self] _ in
                let item = SimpleTextActivity(content: reqCurl, requestUrl: selectedModel.requestURL!)
                self.displayShareSheet(content: item, sender: sender)
            }
            actionSheetController.addAction(curlAction)
        }

        actionSheetController.popoverPresentationController?.barButtonItem = sender

        self.present(actionSheetController, animated: true, completion: nil)
    }

    func displayShareSheet(content: UIActivityItemSource, sender: UIBarButtonItem) {
        let activityViewController = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }

    func shareLog(full: Bool, sender: UIBarButtonItem) {
        var tempString = """
        ** INFO **
        \(getInfoStringFromObject(self.selectedModel).string)

        ** REQUEST **
        \(getRequestStringFromObject(self.selectedModel).string)

        ** RESPONSE **
        \(getResponseStringFromObject(self.selectedModel).string)

        logged via netfox - [https://github.com/kasketis/netfox]\n
        """

        if full {
            let requestFilePath = self.selectedModel.getRequestBodyFilepath()
            if let requestFileData = try? String(contentsOf: URL(fileURLWithPath: requestFilePath as String), encoding: .utf8) {
                tempString += requestFileData
            }

            let responseFilePath = self.selectedModel.getResponseBodyFilepath()
            if let responseFileData = try? String(contentsOf: URL(fileURLWithPath: responseFilePath as String), encoding: .utf8) {
                tempString += responseFileData
            }
        }

        do {
            let url = try saveLogFile(tempString)
            displayShareSheet(content: LogFileActivity(content: url), sender: sender)
        } catch {
            displayShareSheet(
                content: SimpleTextActivity(
                    content: tempString,
                    requestUrl: selectedModel.requestURL!
                ),
                sender: sender
            )
        }
    }

    func saveLogFile(_ text: String) throws -> URL {
        enum SaveError: Error {
            case noData
        }

        guard let data = text.data(using: .utf8) else {
            throw SaveError.noData
        }

        let url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("log.txt")
        try data.write(to: url)
        return url
    }

    func getInfoStringFromObject(_ object: NFXHTTPModel) -> NSAttributedString {
        let general = """
            [URL]
            \(object.requestURL!)

            [Method]
            \(object.requestMethod!)

            [Request date]
            \(object.requestDate!)

            [Timeout]
            \(object.requestTimeout!)

            [Cache policy]
            \(object.requestCachePolicy!)
            """

        let responseValues: String

        if object.noResponse {
            responseValues = ""
        } else {
            responseValues = """

            [Status]
            \(object.responseStatus!)

            [Response date]
            \(object.responseDate!)

            [Time interval]
            \(object.timeInterval!)
            """
        }

        return formatNFXString("\(general)\(responseValues)")
    }

    func getRequestStringFromObject(_ object: NFXHTTPModel) -> NSAttributedString {
        var tempString = "-- Headers --\n\n"

        if let headers = object.requestHeaders, !headers.isEmpty {
            for (key, val) in headers {
                tempString += "[\(key)] \n\(val)\n\n"
            }
        } else {
            tempString += "Request headers are empty\n\n"
        }

        tempString += "\n-- Body --\n\n"
        if object.requestBodyLength == 0 {
            tempString += "Request body is empty\n"
        } else if object.requestBodyLength > 1024 {
            tempString += "Too long to show. If you want to see it, please tap the following button\n"
        } else {
            tempString += "\(object.getRequestBody())\n"
        }

        return formatNFXString(tempString)
    }

    func getResponseStringFromObject(_ object: NFXHTTPModel) -> NSAttributedString {
        guard !object.noResponse else {
            return NSMutableAttributedString(string: "No response")
        }

        var tempString = "-- Headers --\n\n"

        if let headers = object.responseHeaders, !headers.isEmpty {
            for (key, val) in headers {
                tempString += "[\(key)] \n\(val)\n\n"
            }
        } else {
            tempString += "Response headers are empty\n\n"
        }

        tempString += "\n-- Body --\n\n"
        if object.responseBodyLength == 0 {
            tempString += "Response body is empty\n"
        } else if object.responseBodyLength > 1024 {
            tempString += "Too long to show. If you want to see it, please tap the following button\n"
        } else {
            tempString += "\(object.getResponseBody())\n"
        }

        return formatNFXString(tempString)
    }

    func formatNFXString(_ string: String) -> NSAttributedString {
        let tempMutableString = NSMutableAttributedString(string: string)

        let fullRange = NSRange(location: 0, length: string.count)

        let regexBodyHeaders = try! NSRegularExpression(pattern: "(\\-- Body \\--)|(\\-- Headers \\--)", options: NSRegularExpression.Options.caseInsensitive)
        let matchesBodyHeaders = regexBodyHeaders.matches(in: string, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: fullRange) as Array<NSTextCheckingResult>

        for match in matchesBodyHeaders {
            tempMutableString.addAttribute(.font, value: NFXFont.NFXFontBold(size: 14), range: match.range)
            tempMutableString.addAttribute(.foregroundColor, value: NFXColor.NFXOrangeColor(), range: match.range)
        }

        let regexKeys = try! NSRegularExpression(pattern: "\\[.+?\\]", options: NSRegularExpression.Options.caseInsensitive)
        let matchesKeys = regexKeys.matches(in: string, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: fullRange) as Array<NSTextCheckingResult>

        for match in matchesKeys {
            tempMutableString.addAttribute(
                .foregroundColor,
                value: NFXColor.NFXBlackColor(),
                range: match.range
            )

            tempMutableString.addAttribute(
                .link,
                value: (string as NSString).substring(with: match.range),
                range: match.range
            )
        }

        return tempMutableString
    }
}

extension NetfoxDetailViewController: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let decodedURL = URL.absoluteString.removingPercentEncoding
        switch decodedURL {
        case "[URL]":
            guard let queryItems = self.selectedModel.requestURLQueryItems, !queryItems.isEmpty else {
                return false
            }
            let urlDetailsController = NFXURLDetailsController()
            urlDetailsController.selectedModel = self.selectedModel
            self.navigationController?.pushViewController(urlDetailsController, animated: true)
            return true
        default:
            return false
        }
    }
}

#endif
