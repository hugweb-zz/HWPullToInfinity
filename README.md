# HWPullToInfinity

Swift pull to refresh and infinite scrolling finally met for your favorites UITableView &amp; UICollectionView

<img src="https://github.com/hugweb/HWPullToInfinity/blob/master/HWPullToInfinityExample/Assets.xcassets/example.dataset/example.gif"/>

##Pull to refresh

```swift

tableView.addPullToRefreshWithActionHandler { () -> Void in
  // TODO
}
tableView.pullRefreshColor = UIColor.darkGrayColor()
    
```

##Infinite scroll

```swift

tableView.addInfiniteScrollingWithActionHandler { () -> Void in
  // TODO
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
