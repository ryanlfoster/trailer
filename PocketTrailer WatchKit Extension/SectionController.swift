
import WatchKit

final class SectionController: WKInterfaceController {

	@IBOutlet weak var table: WKInterfaceTable!

	static var stateIsDirty = false

	override func awakeWithContext(context: AnyObject?) {
		super.awakeWithContext(context)

		dataReadonly = true
		Settings.clearCache()

		buildUI()
	}

	override func willActivate() {
		if SectionController.stateIsDirty {
			buildUI()
			SectionController.stateIsDirty = false
		}
		super.willActivate()
	}

	override func didDeactivate() {
		super.didDeactivate()
	}

	@IBAction func clearMergedSelected() {
		SectionController.stateIsDirty = true
		presentControllerWithName("Command Controller", context: ["command": "clearAllMerged"])
	}

	@IBAction func clearClosedSelected() {
		SectionController.stateIsDirty = true
		presentControllerWithName("Command Controller", context: ["command": "clearAllClosed"])
	}

	@IBAction func markAllReadSelected() {
		SectionController.stateIsDirty = true
		presentControllerWithName("Command Controller", context: ["command": "markEverythingRead"])
	}

	@IBAction func refreshSelected() {
		SectionController.stateIsDirty = true
		presentControllerWithName("Command Controller", context: ["command": "refresh"])
	}

	class titleEntry {
		var title: String
		init(_ t: String) { title = t }
	}

	class attributedTitleEntry {
		var title: NSAttributedString
		init(_ t: NSAttributedString) { title = t }
	}

	class prEntry {
		var section: PullRequestSection
		init(_ s: PullRequestSection) { section = s }
	}

	class issueEntry {
		var section: PullRequestSection
		init(_ s: PullRequestSection) { section = s }
	}

	override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
		var ri = rowIndex
		var type = "PRS"
		if Settings.showIssuesMenu {
			if ri > PullRequestSection.All.rawValue {
				ri -= PullRequestSection.All.rawValue
				ri--
				type = "ISSUES"
			}
		}
		pushControllerWithName("ListController", context: [ SECTION_KEY: ri, TYPE_KEY: type ] )
	}

	private func buildUI() {

		var rowTypes = [AnyObject]()

		let totalPrs = PullRequest.countAllRequestsInMoc(mainObjectContext)
		if totalPrs==0 {
			rowTypes.append(attributedTitleEntry(DataManager.reasonForEmptyWithFilter(nil)))
		} else {
			rowTypes.append(titleEntry("\(totalPrs) PULL REQUESTS"))
			rowTypes.append(prEntry(PullRequestSection.Mine))
			rowTypes.append(prEntry(PullRequestSection.Participated))
			rowTypes.append(prEntry(PullRequestSection.Merged))
			rowTypes.append(prEntry(PullRequestSection.Closed))
			rowTypes.append(prEntry(PullRequestSection.All))
		}

		if Settings.showIssuesMenu {
			let totalIssues = Issue.countAllIssuesInMoc(mainObjectContext)
			if totalIssues==0 {
				rowTypes.append(attributedTitleEntry(DataManager.reasonForEmptyIssuesWithFilter(nil)))
			} else {
				rowTypes.append(titleEntry("\(totalIssues) ISSUES"))
				rowTypes.append(issueEntry(PullRequestSection.Mine))
				rowTypes.append(issueEntry(PullRequestSection.Participated))
				rowTypes.append(issueEntry(PullRequestSection.Merged))
				rowTypes.append(issueEntry(PullRequestSection.Closed))
				rowTypes.append(issueEntry(PullRequestSection.All))
			}
		}

		setTitle("Sections")

		var rowControllerTypes = [String]()
		for type in rowTypes {
			if type is titleEntry || type is attributedTitleEntry{
				rowControllerTypes.append("TitleRow")
			} else if type is prEntry || type is issueEntry {
				rowControllerTypes.append("SectionRow")
			}
		}
		table.setRowTypes(rowControllerTypes)

		var index = 0
		for type in rowTypes {
			if let t = type as? titleEntry {
				let r = table.rowControllerAtIndex(index) as! TitleRow
				r.titleL.setText(t.title)
			} else if let t = type as? attributedTitleEntry {
				let r = table.rowControllerAtIndex(index) as! TitleRow
				r.group.setBackgroundColor(UIColor.whiteColor())
				r.group.setAlpha(1.0)
				r.titleL.setAttributedText(t.title)
			} else if let t = type as? prEntry {
				(table.rowControllerAtIndex(index) as! SectionRow).setPr(t.section)
			} else if let t = type as? issueEntry {
				(table.rowControllerAtIndex(index) as! SectionRow).setIssue(t.section)
			}
			index++
		}
	}
}
