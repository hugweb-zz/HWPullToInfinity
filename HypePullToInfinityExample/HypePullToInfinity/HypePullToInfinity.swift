//
//  HypePullToInfinity.swift
//  HypeUGC
//
//  Created by Hugues Blocher on 21/01/16.
//  Copyright © 2016 Hype. All rights reserved.
//

import UIKit
import QuartzCore
import ObjectiveC


// MARK: Pull to refresh scrollView extension

extension UIScrollView {
    
    var pullRefreshColor: UIColor? {
        get { return self.refreshControlView.tintColor }
        set(newValue) {
            self.refreshControlView.tintColor = newValue
        }
    }
    
    private struct PullAssociatedKeys {
        static var refreshControlView: UIRefreshControl?
        static var pullRefreshHasBeenSetup : Bool = false
        static var pullRefreshHandler: (() -> Void)?
    }
    
    private class pullRefreshHandlerWrapper {
        var handler: (() -> Void)
        init(handler: (() -> Void)) { self.handler = handler }
    }
    
    private var pullRefreshHandler: (() -> Void)? {
        get {
            if let wrapper = objc_getAssociatedObject(self, &PullAssociatedKeys.pullRefreshHandler) as? pullRefreshHandlerWrapper { return wrapper.handler }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &PullAssociatedKeys.pullRefreshHandler, pullRefreshHandlerWrapper(handler: newValue!), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var refreshControlView: UIRefreshControl {
        get {
            return objc_getAssociatedObject(self, &PullAssociatedKeys.refreshControlView) as! UIRefreshControl
        }
        set {
            objc_setAssociatedObject(self, &PullAssociatedKeys.refreshControlView, newValue as UIRefreshControl?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var pullRefreshHasBeenSetup: Bool {
        get {
            guard let number = objc_getAssociatedObject(self, &PullAssociatedKeys.pullRefreshHasBeenSetup) as? NSNumber else { return false }
            return number.boolValue
        }
        set(value) {
            objc_setAssociatedObject(self, &PullAssociatedKeys.pullRefreshHasBeenSetup, NSNumber(bool: value), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func addPullToRefreshWithActionHandler(actionHandler: () -> Void) {
        if !self.pullRefreshHasBeenSetup {
            let view: UIRefreshControl = UIRefreshControl()
            view.addTarget(self, action: "triggerPullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
            view.layer.zPosition = self.layer.zPosition - 1
            self.refreshControlView = view
            self.pullRefreshHandler = actionHandler
            self.addSubview(view)
            self.pullRefreshHasBeenSetup = true
        }
    }
    
    func addPullToRefreshWithTitleAndActionHandler(pullToRefreshTitle: NSAttributedString?, actionHandler: () -> Void) {
        if !self.pullRefreshHasBeenSetup {
            let view: UIRefreshControl = UIRefreshControl()
            if let title = pullToRefreshTitle { view.attributedTitle = title }
            view.addTarget(self, action: "triggerPullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
            view.layer.zPosition = self.layer.zPosition - 1
            self.refreshControlView = view
            self.pullRefreshHandler = actionHandler
            self.addSubview(view)
            self.pullRefreshHasBeenSetup = true
        }
    }
    
    func triggerPullToRefresh() {
        if let handler = self.pullRefreshHandler { handler() }
    }
    
    func stopPullToRefresh() {
        self.refreshControlView.endRefreshing()
    }
}

// MARK: Infinite Scroll

enum HypePullToInfinityState {
    case Stopped
    case Triggered
    case Loading
    case All
}

let HypePullToInfinityViewHeight: CGFloat = 60
let HypePullToInfinityViewWidth: CGFloat = HypePullToInfinityViewHeight

class HypePullToInfinityView: UIView {

    // MARK: Infinite properties
    
    var isHorizontal: Bool = false

    private weak var scrollView: UIScrollView?
    private var infiniteScrollingHandler: (() -> Void)?
    private var viewForState: [AnyObject] = ["", "", "", ""]
    private var originalInset: CGFloat = 0.0
    private var wasTriggeredByUser: Bool = false
    private var isObserving: Bool = false
    private var enabled: Bool = false
    private var isSetup: Bool = false

    private var _activityIndicatorView : UIActivityIndicatorView?
    private var activityIndicatorView : UIActivityIndicatorView {
        get {
            if _activityIndicatorView == nil {
                _activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
                _activityIndicatorView?.color = UIColor.grayColor()
                _activityIndicatorView?.hidesWhenStopped = true
                self.addSubview(_activityIndicatorView!)
            }
            return _activityIndicatorView!
        }
    }
    
    private var _state: HypePullToInfinityState = .Stopped
    private var state: HypePullToInfinityState {
        get {
            return _state
        }
        set(newState) {
            if _state == newState {
                return
            }
            let previousState: HypePullToInfinityState = state
            _state = newState
            for otherView in self.viewForState {
                if otherView is UIView {
                    otherView.removeFromSuperview()
                }
            }
            let customView: AnyObject = self.viewForState[newState.hashValue]
            if let custom = customView as? UIView {
                self.addSubview(custom)
                let viewBounds: CGRect = custom.bounds
                let x = CGFloat(roundf(Float((self.bounds.size.width - viewBounds.size.width) / 2)))
                let y = CGFloat(roundf(Float((self.bounds.size.height - viewBounds.size.height) / 2)))
                let origin: CGPoint = CGPointMake(x, y)
                custom.frame = CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)
            } else {
                let viewBounds: CGRect = self.activityIndicatorView.bounds
                let x = CGFloat(roundf(Float((self.bounds.size.width - viewBounds.size.width) / 2)))
                let y = CGFloat(roundf(Float((self.bounds.size.height - viewBounds.size.height) / 2)))
                let origin: CGPoint = CGPointMake(x, y)
                self.activityIndicatorView.frame = CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)
                switch newState {
                case .Stopped:
                    self.activityIndicatorView.stopAnimating()
                case .Triggered:
                    self.activityIndicatorView.startAnimating()
                case .Loading:
                    self.activityIndicatorView.startAnimating()
                default: break
                }
            }
            if previousState == .Triggered && newState == .Loading && self.enabled {
                if let handler = self.infiniteScrollingHandler {
                    handler()
                }
            }
        }
    }
    
    // MARK: Infinite initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.autoresizingMask = .FlexibleWidth
        self.enabled = true
    }
    
    convenience init () {
        self.init(frame:CGRectZero)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func layoutSubviews() {
        self.activityIndicatorView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2)
    }

    // MARK: Infinite scrollView
    
    func resetScrollViewContentInset() {
        var currentInsets: UIEdgeInsets = self.scrollView!.contentInset
        if self.isHorizontal {
            currentInsets.right = self.originalInset
        } else {
            currentInsets.bottom = self.originalInset
        }
        self.setScrollViewContentInset(currentInsets)
    }
    
    func setScrollViewContentInsetForInfiniteScrolling() {
        var currentInsets: UIEdgeInsets = self.scrollView!.contentInset
        if self.isHorizontal {
            currentInsets.right = self.originalInset + HypePullToInfinityViewWidth
        } else {
            currentInsets.bottom = self.originalInset + HypePullToInfinityViewHeight
        }
        self.setScrollViewContentInset(currentInsets)
    }

    func setScrollViewContentInset(contentInset: UIEdgeInsets) {
        UIView.animateWithDuration(0.3, delay: 0, options: [.AllowUserInteraction, .BeginFromCurrentState], animations: {() -> Void in
            self.scrollView!.contentInset = contentInset
            }, completion: { _ in })
    }
    
    func scrollViewDidScroll(contentOffset: CGPoint) {
        if self.state != .Loading && self.enabled {
            if self.isHorizontal {
                let scrollViewContentWidth: CGFloat = self.scrollView!.contentSize.width
                let scrollOffsetThreshold: CGFloat = scrollViewContentWidth - self.scrollView!.bounds.size.width
                if !self.scrollView!.dragging && self.state == .Triggered {
                    self.state = .Loading
                }
                else if contentOffset.x > scrollOffsetThreshold && self.state == .Stopped && self.scrollView!.dragging {
                    self.state = .Triggered
                }
                else if contentOffset.x < scrollOffsetThreshold && self.state != .Stopped {
                    self.state = .Stopped
                }
            } else {
                let scrollViewContentHeight: CGFloat = self.scrollView!.contentSize.height
                let scrollOffsetThreshold: CGFloat = scrollViewContentHeight - self.scrollView!.bounds.size.height
                if !self.scrollView!.dragging && self.state == .Triggered {
                    self.state = .Loading
                }
                else if contentOffset.y > scrollOffsetThreshold && self.state == .Stopped && self.scrollView!.dragging {
                    self.state = .Triggered
                }
                else if contentOffset.y < scrollOffsetThreshold && self.state != .Stopped {
                    self.state = .Stopped
                }
            }
        }
    }
    
    // MARK: Infinite observing
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == "contentOffset") {
            let new = (change?[NSKeyValueChangeNewKey] as! NSValue).CGPointValue()
            self.scrollViewDidScroll(new)
        } else if (keyPath == "contentSize") {
            self.layoutSubviews()
            if self.isHorizontal {
                self.frame = CGRectMake(self.scrollView!.contentSize.width, 0, HypePullToInfinityViewWidth, self.scrollView!.contentSize.height)
            } else {
                self.frame = CGRectMake(0, self.scrollView!.contentSize.height, self.bounds.size.width, HypePullToInfinityViewHeight)
            }
        }
    }
    
    // MARK: Infinite setters
    
    func setCustomView(view: UIView, forState state: HypePullToInfinityState) {
        let viewPlaceholder: AnyObject = view
        if state == .All {
            self.viewForState[0...3] = [viewPlaceholder, viewPlaceholder, viewPlaceholder]
        } else {
            self.viewForState[state.hashValue] = viewPlaceholder
        }
        self.state = state
    }
    
    func setActivityIndicatorViewColor(color: UIColor) {
        self.activityIndicatorView.tintColor = color
    }
    
    func triggerRefresh() {
        self.state = .Triggered
        self.state = .Loading
    }
    
    func startAnimating() {
        self.state = .Loading
    }
    
    func stopAnimating() {
        self.state = .Stopped
    }
}

// MARK: Infinite scrollView extension

extension UIScrollView {
    
    private struct InfiniteAssociatedKeys {
        static var infiniteScrollingView: HypePullToInfinityView?
        static var showsInfiniteScrolling : Bool = false
        static var infiniteScrollingHasBeenSetup : Bool = false
    }
    
    var infiniteScrollingHasBeenSetup: Bool {
        get {
            guard let number = objc_getAssociatedObject(self, &InfiniteAssociatedKeys.infiniteScrollingHasBeenSetup) as? NSNumber else {
                return false
            }
            return number.boolValue
        }
        
        set(value) {
            objc_setAssociatedObject(self,&InfiniteAssociatedKeys.infiniteScrollingHasBeenSetup,NSNumber(bool: value),objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var showsInfiniteScrolling : Bool {
        get {
            return !self.infiniteScrollingView.hidden
        }
        set(value) {
            self.infiniteScrollingView.hidden = !showsInfiniteScrolling
            if !showsInfiniteScrolling {
                if self.infiniteScrollingView.isObserving {
                    self.removeObserver(self.infiniteScrollingView, forKeyPath: "contentOffset")
                    self.removeObserver(self.infiniteScrollingView, forKeyPath: "contentSize")
                    self.infiniteScrollingView.resetScrollViewContentInset()
                    self.infiniteScrollingView.isObserving = false
                }
            } else {
                if !self.infiniteScrollingView.isObserving {
                    self.addObserver(self.infiniteScrollingView, forKeyPath: "contentOffset", options: .New, context: nil)
                    self.addObserver(self.infiniteScrollingView, forKeyPath: "contentSize", options: .New, context: nil)
                    self.infiniteScrollingView.setScrollViewContentInsetForInfiniteScrolling()
                    self.infiniteScrollingView.isObserving = true
                    self.infiniteScrollingView.setNeedsLayout()
                    if self.infiniteScrollingView.isHorizontal {
                        self.infiniteScrollingView.frame = CGRectMake(self.contentSize.width, 0, HypePullToInfinityViewWidth, self.contentSize.height)
                    } else {
                        self.infiniteScrollingView.frame = CGRectMake(0, self.contentSize.height, self.infiniteScrollingView.bounds.size.width, HypePullToInfinityViewHeight)
                    }
                }
            }
        }
    }
    
    var infiniteScrollingView: HypePullToInfinityView {
        get {
            return objc_getAssociatedObject(self, &InfiniteAssociatedKeys.infiniteScrollingView) as! HypePullToInfinityView
        }
        set {
            self.willChangeValueForKey("UIScrollViewInfiniteScrollingView")
            objc_setAssociatedObject(self, &InfiniteAssociatedKeys.infiniteScrollingView, newValue as HypePullToInfinityView?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.didChangeValueForKey("UIScrollViewInfiniteScrollingView")
        }
    }
    
    func addInfiniteScrollingWithActionHandler(actionHandler: () -> Void) {
        if !self.infiniteScrollingHasBeenSetup {
            let view: HypePullToInfinityView = HypePullToInfinityView(frame: CGRectMake(0, self.contentSize.height, self.bounds.size.width, HypePullToInfinityViewHeight))
            view.infiniteScrollingHandler = actionHandler
            view.scrollView = self
            self.addSubview(view)
            view.originalInset = self.contentInset.bottom
            self.infiniteScrollingView = view
            self.showsInfiniteScrolling = true
            self.infiniteScrollingHasBeenSetup = true
        }
    }
    
    func addHorizontalInfiniteScrollingWithActionHandler(actionHandler: () -> Void) {
        if !self.infiniteScrollingHasBeenSetup {
            let view: HypePullToInfinityView = HypePullToInfinityView(frame: CGRectMake(self.contentSize.width, 0, HypePullToInfinityViewWidth, self.contentSize.height))
            view.infiniteScrollingHandler = actionHandler
            view.scrollView = self
            view.isHorizontal = true
            self.addSubview(view)
            view.originalInset = self.contentInset.right
            self.infiniteScrollingView = view
            self.showsInfiniteScrolling = true
            self.infiniteScrollingHasBeenSetup = true
        }
    }
    
    func triggerInfiniteScrolling() {
        self.infiniteScrollingView.state = .Triggered
        self.infiniteScrollingView.startAnimating()
    }
}
