
import UIKit

final class PRCell: UITableViewCell {

	private let unreadCount = CountLabel(frame: CGRectZero)
	private let readCount = CountLabel(frame: CGRectZero)
	private var failedToLoadImage: String?
	private var waitingForImageInPath: String?

	@IBOutlet weak var _image: UIImageView!
	@IBOutlet weak var _title: UILabel!
	@IBOutlet weak var _description: UILabel!
	@IBOutlet weak var _statuses: UILabel!

	override func awakeFromNib() {
		unreadCount.textColor = UIColor.whiteColor()
		contentView.addSubview(unreadCount)

		readCount.textColor = UIColor.darkGrayColor()
		contentView.addSubview(readCount)

		let bg = UIView()
		bg.backgroundColor = UIColor(red: 0.82, green: 0.88, blue: 0.97, alpha: 1.0)
		selectedBackgroundView = bg

		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("networkStateChanged"), name: kReachabilityChangedNotification, object: nil)
	}

	private var needsConstraints = true

	override func updateConstraints() {

		if needsConstraints {
			needsConstraints = false

			contentView.addConstraints([

				NSLayoutConstraint(item: _image,
					attribute: NSLayoutAttribute.CenterX,
					relatedBy: NSLayoutRelation.Equal,
					toItem: readCount,
					attribute: NSLayoutAttribute.CenterX,
					multiplier: 1,
					constant: -23),

				NSLayoutConstraint(item: _image,
					attribute: NSLayoutAttribute.CenterY,
					relatedBy: NSLayoutRelation.Equal,
					toItem: readCount,
					attribute: NSLayoutAttribute.CenterY,
					multiplier: 1,
					constant: -23),

				NSLayoutConstraint(item: _image,
					attribute: NSLayoutAttribute.CenterX,
					relatedBy: NSLayoutRelation.Equal,
					toItem: unreadCount,
					attribute: NSLayoutAttribute.CenterX,
					multiplier: 1,
					constant: 23),

				NSLayoutConstraint(item: _image,
					attribute: NSLayoutAttribute.CenterY,
					relatedBy: NSLayoutRelation.Equal,
					toItem: unreadCount,
					attribute: NSLayoutAttribute.CenterY,
					multiplier: 1,
					constant: 23)
				])
		}
		super.updateConstraints()
	}

	func networkStateChanged() {
		dispatch_async(dispatch_get_main_queue()) { [weak self] in
			if self!.failedToLoadImage == nil { return }
			if api.currentNetworkStatus != NetworkStatus.NotReachable {
				self!.loadImageAtPath(self!.failedToLoadImage)
			}
		}
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	func setPullRequest(pullRequest: PullRequest) {
		let detailFont = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
		_title.attributedText = pullRequest.titleWithFont(_title.font, labelFont: detailFont.fontWithSize(detailFont.pointSize-2), titleColor: UIColor.darkTextColor())
		_description.attributedText = pullRequest.subtitleWithFont(detailFont, lightColor: UIColor.lightGrayColor(), darkColor: UIColor.darkGrayColor())
		var statusText : NSMutableAttributedString?
		var statusCount = 0
		if Settings.showStatusItems {
			let statusItems = pullRequest.displayedStatuses() + pullRequest.displayedStatuses()
			statusCount = statusItems.count
			if statusCount > 0 {

				let paragraphStyle = NSMutableParagraphStyle()
				paragraphStyle.headIndent = 103.0
				paragraphStyle.paragraphSpacing = 6.0

				let statusAttributes = [
					NSFontAttributeName: UIFont(name: "Courier", size: 10)!,
					NSParagraphStyleAttributeName: paragraphStyle]

				statusText = NSMutableAttributedString()
				statusText?.appendAttributedString(NSAttributedString(string: "\n", attributes: statusAttributes))

				for status in statusItems {
					var lineAttributes = statusAttributes
					lineAttributes[NSForegroundColorAttributeName] = status.colorForDisplay()
					let text = status.displayText()
					statusText?.appendAttributedString(NSAttributedString(string: text, attributes: lineAttributes))
					if --statusCount > 0 {
						statusText?.appendAttributedString(NSAttributedString(string: "\n", attributes: lineAttributes))
					}
				}
			}
		}
		_statuses.attributedText = statusText

		var _commentsNew = 0
		let _commentsTotal = pullRequest.totalComments?.integerValue ?? 0

		if Settings.showCommentsEverywhere || pullRequest.isMine() || pullRequest.commentedByMe() {
			_commentsNew = pullRequest.unreadComments?.integerValue ?? 0
		}

		readCount.text = itemCountFormatter.stringFromNumber(_commentsTotal)
		let readSize = readCount.sizeThatFits(CGSizeMake(200, 14))
		readCount.hidden = (_commentsTotal == 0)

		unreadCount.hidden = (_commentsNew == 0)
		unreadCount.text = itemCountFormatter.stringFromNumber(_commentsNew)

		loadImageAtPath(pullRequest.userAvatarUrl)

		if let statusString = statusText?.string {
			accessibilityLabel = "\(pullRequest.accessibleTitle()), \(unreadCount.text) unread comments, \(readCount.text) total comments, \(pullRequest.accessibleSubtitle()). \(statusCount) statuses: \(statusString)"
		} else {
			accessibilityLabel = "\(pullRequest.accessibleTitle()), \(unreadCount.text) unread comments, \(readCount.text) total comments, \(pullRequest.accessibleSubtitle())"
		}
	}

	func setIssue(issue: Issue) {
		let detailFont = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
		_title.attributedText = issue.titleWithFont(_title.font, labelFont: detailFont.fontWithSize(detailFont.pointSize-2), titleColor: UIColor.darkTextColor())
		_description.attributedText = issue.subtitleWithFont(detailFont, lightColor: UIColor.lightGrayColor(), darkColor: UIColor.darkGrayColor())
		_statuses.attributedText = nil

		var _commentsNew = 0
		let _commentsTotal = issue.totalComments?.integerValue ?? 0

		if Settings.showCommentsEverywhere || issue.isMine() || issue.commentedByMe() {
			_commentsNew = issue.unreadComments?.integerValue ?? 0
		}

		readCount.text = itemCountFormatter.stringFromNumber(_commentsTotal)
		let readSize = readCount.sizeThatFits(CGSizeMake(200, 14))
		readCount.hidden = (_commentsTotal == 0)

		unreadCount.hidden = (_commentsNew == 0)
		unreadCount.text = itemCountFormatter.stringFromNumber(_commentsNew)

		loadImageAtPath(issue.userAvatarUrl)

		accessibilityLabel = "\(issue.accessibleTitle()), \(unreadCount.text) unread comments, \(readCount.text) total comments, \(issue.accessibleSubtitle())"
	}

	private func loadImageAtPath(imagePath: String?) {
		waitingForImageInPath = imagePath
		if let path = imagePath {
			if (!api.haveCachedAvatar(path) { [weak self] image in
				if self!.waitingForImageInPath == path {
					if image != nil {
						// image loaded
						self!._image.image = image
						self!.failedToLoadImage = nil
					} else {
						// load failed / no image
						self!._image.image = UIImage(named: "avatarPlaceHolder")
						self!.failedToLoadImage = imagePath
					}
					self!.waitingForImageInPath = nil
				}
			}) {
				// prepare UI for over-the-network load
				_image.image = UIImage(named: "avatarPlaceHolder")
				failedToLoadImage = nil
			}
		} else {
			failedToLoadImage = nil
		}
	}

	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated:animated)
		tone(selected)
	}

	override func setHighlighted(highlighted: Bool, animated: Bool) {
		super.setHighlighted(highlighted, animated:animated)
		tone(highlighted)
	}

	func tone(tone: Bool)
	{
		unreadCount.backgroundColor = UIColor.redColor()
		readCount.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
	}
}