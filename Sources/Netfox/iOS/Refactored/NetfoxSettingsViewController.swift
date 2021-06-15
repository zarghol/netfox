//
//  NetfoxSettingsController.swift
//  
//
//  Created by Clément Nonn on 15/06/2021.
//

#if os(iOS)

import UIKit
import MessageUI

class NetfoxSettingsController: UITableViewController, MFMailComposeViewControllerDelegate, DataCleaner {

    let nfxVersionString = "netfox - \(nfxVersion)"
    let nfxURL = URL(string:"https://github.com/zarghol/netfox")!

    var tableData = [HTTPModelShortType]()
    var filters = [Bool]()

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Settings"

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BasicCell")

        tableView.tableFooterView = UIView()

        self.tableData = HTTPModelShortType.allValues
        self.filters = NFX.sharedInstance().getCachedFilters()

        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage.NFXStatistics(),
                style: .plain,
                target: self,
                action: #selector(NetfoxSettingsController.statisticsButtonPressed)
            ),
            UIBarButtonItem(
                image: UIImage.NFXInfo(),
                style: .plain,
                target: self,
                action: #selector(NetfoxSettingsController.infoButtonPressed)
            )
        ]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NFX.sharedInstance().cacheFilters(self.filters)
    }

    @objc func nfxURLButtonPressed() {
        UIApplication.shared.openURL(nfxURL)
    }

    @objc func infoButtonPressed() {
        self.navigationController?.pushViewController(NFXInfoController_iOS(), animated: true)
    }

    @objc func statisticsButtonPressed() {
        self.navigationController?.pushViewController(NFXStatisticsController_iOS(), animated: true)
    }

    func reloadTableData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.setNeedsDisplay()
        }
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 2, 3, 4: return 1
        case 1: return self.tableData.count

        default: return 0
        }
    }

    private var shareLogsCell: UITableViewCell?

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        cell.textLabel?.font = UIFont.NFXFont(size: 14)
        cell.tintColor = UIColor.NFXOrangeColor()

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "Logging"
            let nfxEnabledSwitch = UISwitch()
            nfxEnabledSwitch.setOn(NFX.sharedInstance().isEnabled(), animated: false)
            nfxEnabledSwitch.addTarget(self, action: #selector(NFXSettingsController_iOS.nfxEnabledSwitchValueChanged(_:)), for: .valueChanged)
            cell.accessoryView = nfxEnabledSwitch

        case 1:
            let shortType = tableData[indexPath.row]
            cell.textLabel?.text = shortType.rawValue
            configureCell(cell, indexPath: indexPath)

        case 2:
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = "Share Session Logs"
            cell.textLabel?.textColor = UIColor.NFXGreenColor()
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .callout)

            shareLogsCell = cell

        case 3:
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = "Clear data"
            cell.textLabel?.textColor = UIColor.NFXRedColor()
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .callout)

        case 4:
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .callout)

            let attrText = NSMutableAttributedString(
                string: "\(nfxVersionString) - \(nfxURL.absoluteString)",
                attributes: [
                    .foregroundColor: UIColor.NFXOrangeColor()
                ]
            )
            let range: NSRange = (attrText.string as NSString).range(of: nfxURL.absoluteString)
            attrText.addAttribute(.link, value: nfxURL, range: range)

            cell.textLabel?.attributedText = attrText

        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }

        let filtersInfoLabel = UILabel()
        filtersInfoLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        filtersInfoLabel.textColor = UIColor.NFXGray44Color()
        filtersInfoLabel.textAlignment = .center
        filtersInfoLabel.text = "Select the types of responses that you want to see"
        filtersInfoLabel.numberOfLines = 0

        return filtersInfoLabel
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            let cell = tableView.cellForRow(at: indexPath)
            self.filters[indexPath.row] = !self.filters[indexPath.row]
            configureCell(cell, indexPath: indexPath)

        case 2:
            shareSessionLogsPressed()

        case 3:
            clearDataButtonPressedOnTableIndex(indexPath)

        case 4:
            nfxURLButtonPressed()

        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 40

        default:
            return 0
        }
    }

    func configureCell(_ cell: UITableViewCell?, indexPath: IndexPath) {
        guard let cell = cell else { return }

        if self.filters[indexPath.row] {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }

    @objc func nfxEnabledSwitchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            NFX.sharedInstance().enable()
        } else {
            NFX.sharedInstance().disable()
        }
    }

    func clearDataButtonPressedOnTableIndex(_ index: IndexPath){
        clearData(sourceView: tableView, originingIn: tableView.rectForRow(at: index)) { }
    }

    func shareSessionLogsPressed() {
        let url = URL(fileURLWithPath: NFXPath.SessionLog)
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popoverPresentationController = controller.popoverPresentationController, let sourceCell = shareLogsCell {
            popoverPresentationController.sourceView = sourceCell
            popoverPresentationController.sourceRect = sourceCell.bounds
        }
        self.present(controller, animated: true, completion: nil)

//        if MFMailComposeViewController.canSendMail() {
//            let mailComposer = MFMailComposeViewController()
//            mailComposer.mailComposeDelegate = self
//
//            mailComposer.setSubject("netfox log - Session Log \(NSDate())")
//            if let sessionLogData = NSData(contentsOfFile:  as String) {
//                mailComposer.addAttachmentData(sessionLogData as Data, mimeType: "text/plain", fileName: "session.log")
//            }
//
//            self.present(mailComposer, animated: true, completion: nil)
//        }
    }

//    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//        self.dismiss(animated: true, completion: nil)
//    }
}

#endif

