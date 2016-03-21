# HWPullToInfinity

<br>Swift pull to refresh and infinite scrolling finally met for your favorites UITableView &amp; UICollectionView

![Swift 2 compatible](https://img.shields.io/badge/swift2-compatible-4BC51D.svg?style=flat)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

- [x] Pull to refresh
- [x] Infinite scroll
- [x] UITableView / UICollectionView compatibility
- [x] Vertical / horizontal support

<br><img src="https://github.com/hugweb/HWPullToInfinity/blob/master/HWPullToInfinityExample/Assets.xcassets/example.dataset/example.gif"/>

##Pull to refresh

```swift

tableView.addPullToRefreshWithActionHandler { () -> Void in
  // TODO
  self.tableView.stopPullToRefresh()
}
tableView.pullRefreshColor = UIColor.darkGrayColor()
    
```

##Infinite scroll

```swift

tableView.addInfiniteScrollingWithActionHandler { () -> Void in
  // TODO
  self.tableView.infiniteScrollingView.stopAnimating()
}
tableView.infiniteScrollingView.color = UIColor.darkGrayColor()
    
```

##Requirements
- iOS 8.0+

## Contact

Hugues Blocher

- http://github.com/hugweb
- http://twitter.com/hugweb
- http://www.hugweb.fr

## License

HWPullToInfinity is available under the MIT license.
