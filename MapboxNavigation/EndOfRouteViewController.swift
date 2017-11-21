import UIKit
import MapboxDirections

fileprivate enum ConstraintSpacing: CGFloat {
    case closer = 8.0
    case further = 45.0
}

class EndOfRouteViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var primary: UILabel!
    @IBOutlet weak var secondary: UILabel!
    @IBOutlet weak var endNavigationButton: UIButton!
    @IBOutlet weak var stars: RatingControl!
    @IBOutlet weak var commentView: UITextView!
    @IBOutlet weak var showCommentView: NSLayoutConstraint!
    @IBOutlet weak var hideCommentView: NSLayoutConstraint!
    @IBOutlet weak var ratingCommentsSpacing: NSLayoutConstraint!
    
    //MARK: - Properties
    lazy var placeholder: String = NSLocalizedString("Add an optional comment here.", comment: "Comment Placeholder Text")
    lazy var endNavigation: String = NSLocalizedString("End Navigation", comment: "End Navigation Button Text")
    lazy var sendFeedback: String = NSLocalizedString("Send Feedback", comment: "Send Feedback Button Text")
    
    lazy var geocoder: CLGeocoder = CLGeocoder()
    var dismiss: ((Int, String?) -> Void)?
    var comment: String?
    var rating: Int = 0 {
        didSet {
            rating == 0 ? hideComments() : showComments()
        }
    }
    
    open var destination: Waypoint? {
        didSet {
            guard isViewLoaded else { return }
            updateInterface()
        }
    }

    //MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        clearInterface()
        stars.didChangeRating = { (new) in self.rating = new }
        setPlaceholderText()
        styleCommentView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        roundCornersOfRootView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    //MARK: - IBActions
    @IBAction func endNavigationPressed(_ sender: Any) {
        dismissView()
    }
    
    //MARK: - Private Functions
    private func roundCornersOfRootView() {
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
    }
    
    private func styleCommentView() {
        commentView.layer.cornerRadius = 6.0
        commentView.layer.borderColor = UIColor.lightGray.cgColor
        commentView.layer.borderWidth = 1.0
    }
    
    fileprivate func dismissView() {
        let dismissal: () -> Void = { self.dismiss?(self.rating, self.comment) }
        guard commentView.isFirstResponder else { return _ = dismissal() }
        commentView.resignFirstResponder()
        let fireTime = DispatchTime.now() + 0.3 //Not ideal, but works for now
        DispatchQueue.main.asyncAfter(deadline: fireTime, execute: dismissal)
    }
    
    private func showComments(animated: Bool = true) {
        endNavigationButton.setTitle(sendFeedback, for: .normal)
        endNavigationButton.layoutSubviews()
        
        showCommentView.isActive = true
        hideCommentView.isActive = false
        ratingCommentsSpacing.constant = ConstraintSpacing.closer.rawValue
        
        let layout = view.layoutIfNeeded
        animated ? UIView.animate(withDuration: 0.3, animations: layout) : layout()
    }
    
    private func hideComments(animated: Bool = true) {
        endNavigationButton.setTitle(endNavigation, for: .normal)
        endNavigationButton.layoutSubviews()
        
        showCommentView.isActive = false
        hideCommentView.isActive = true
        ratingCommentsSpacing.constant = ConstraintSpacing.further.rawValue
        
        let layout = view.layoutIfNeeded
        animated ? UIView.animate(withDuration: 0.3, animations: layout) : layout()
    }
    
    
    private func updateInterface() {
        primary.text = string(for: destination)
        guard let coordinate = destination?.coordinate else { return }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { (places, error) in
            guard let place = places?.first,
                  let city = place.locality,
                  let state = place.administrativeArea,
                  error == nil else { return self.secondary.text = nil }
            self.secondary.text = "\(city), \(state)"
        }
    }

    private func clearInterface() {
        [primary, secondary].forEach { $0.text = nil }
        stars.rating = 0
    }
    
    //FIXME: Temporary Placeholder
    private func string(for destination: Waypoint?) -> String {
        guard let destination = destination else { return "Unknown" }
        guard destination.name?.isEmpty ?? false else { return destination.name! }
        let coord = destination.coordinate
        return String(format: "%.2f", coord.latitude) + "," + String(format: "%.2f", coord.longitude)
    }
    
    private func setPlaceholderText() {
        commentView.text = placeholder
        commentView.textColor = .lightGray
    }
}

//MARK: - UITextViewDelegate
extension EndOfRouteViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n" else { return true }
        guard textView.returnKeyType == .send else { textView.resignFirstResponder(); return false }
        dismissView()
        return false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let isEmpty = textView.text?.isEmpty ?? true
        comment = textView.text //Bind data model
        textView.returnKeyType = isEmpty ? .done : .send
        textView.reloadInputViews()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholder {
            textView.text = nil
            textView.textColor = .black
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView.text?.isEmpty ?? true) == true {
            textView.text = placeholder
            textView.textColor = .lightGray
        }
    }
}
