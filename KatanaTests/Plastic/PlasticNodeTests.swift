//
//  File.swift
//  Katana
//
//  Created by Mauro Bolis on 16/08/16.
//  Copyright © 2016 Bending Spoons. All rights reserved.
//

import XCTest
@testable import Katana

class PlasticNodeTests: XCTestCase {
  override func setUp() {
    TestNode.invoked = false
  }
  
  func testLayoutInvoked() {
    let root = TestNode(props: EmptyProps()).makeRoot(store: nil)
    root.render(in: UIView())
    
    XCTAssertEqual(TestNode.invoked, true)
  }
  
  func testNodeDeallocationPlastic() {
    let root = App(props: AppProps(i:0), children: []).makeRoot(store: nil)
    
  
    var references = collectNodes(node: root.node!).map { WeakNode(value: $0) }
    XCTAssert(references.count == 3)
    XCTAssert(references.filter { $0.value != nil }.count == 3)
    
    root.node!.update(with: App(props: AppProps(i:1), children: []))
    XCTAssert(references.count == 3)
    XCTAssertEqual(references.filter { $0.value != nil }.count, 2)
    
    references = collectNodes(node: root.node!).map { WeakNode(value: $0) }
    XCTAssert(references.count == 2)
    XCTAssertEqual(references.filter { $0.value != nil }.count, 2)
    
    root.node!.update(with: App(props: AppProps(i:2), children: []))
    XCTAssert(references.count == 2)
    XCTAssertEqual(references.filter { $0.value != nil }.count, 0)
    
    references = collectNodes(node: root.node!).map { WeakNode(value: $0) }
    XCTAssert(references.count == 0)
    XCTAssertEqual(references.filter { $0.value != nil }.count, 0)
  }
  
  func testViewDeallocationWithPlastic() {

    let root = App(props: AppProps(i:0), children: []).makeRoot(store: nil)
    
    let rootVew = UIView()
    root.render(in: rootVew)
    
    var references = collectView(view: rootVew)
      .filter { $0.tag ==  Katana.VIEWTAG }
      .map { WeakView(value: $0) }
    
    autoreleasepool {
      root.node!.update(with: App(props: AppProps(i:2), children: []))
    }
    
    
    XCTAssertEqual(references.filter { $0.value != nil }.count, 1)
    
    references = collectView(view: rootVew)
      .filter { $0.tag ==  Katana.VIEWTAG }
      .map { WeakView(value: $0) }
    
    XCTAssertEqual(references.count, 1)
  }
  
  
}


private enum Keys {
  case One
}

private struct TestNode: NodeDescription, PlasticNodeDescription {


  typealias NativeView = UIView
  
  var props: EmptyProps
  
  // since we are using a static var here we are not be able to
  // parallelize tests. Let's refactor this test when we will need it
  static var invoked: Bool = false
  
  public static func childrenDescriptions(props: EmptyProps,
                            state: EmptyState,
                            update: @escaping (EmptyState) -> (),
                            dispatch: @escaping StoreDispatch) -> [AnyNodeDescription] {
   
    var props = ViewProps()
    props.setKey(Keys.One)
    
    return [
      View(props: props)
    ]
  }
  
  static func layout(views: ViewsContainer<Keys>, props: EmptyProps, state: EmptyState) -> Void {
    self.invoked = true
  }
}

fileprivate struct MyAppState: State {}

fileprivate struct AppProps: NodeProps {
  var frame: CGRect = CGRect.zero
  var i: Int
  
  static func == (lhs: AppProps, rhs: AppProps) -> Bool {
    return lhs.frame == rhs.frame && lhs.i == rhs.i
  }
  
  init(i: Int) {
    self.i = i
  }
}

fileprivate struct App: NodeDescription {
  
  var props: AppProps
  var children: [AnyNodeDescription] = []
  
  
  fileprivate static func childrenDescriptions(props: AppProps,
                                 state: EmptyState,
                                 update: @escaping (EmptyState) -> (),
                                 dispatch:  @escaping StoreDispatch) -> [AnyNodeDescription] {

    
    
    let i = props.i
    
    if i == 0 {
      var imageProps = ImageProps()
      imageProps.backgroundColor = .blue
      imageProps.setKey(AppKeys.image)
      let image = Image(props: imageProps)
      
      var innerViewProps = ViewProps()
      innerViewProps.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
      innerViewProps.backgroundColor = .gray
      innerViewProps.setKey(AppKeys.innerView)
      let innerView = View(props: innerViewProps)
      
      var viewProps = ViewProps()
      viewProps.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
      viewProps.backgroundColor = .gray
      viewProps.children = [image, innerView]
      viewProps.setKey(AppKeys.container)
      let view = View(props: viewProps)
      
      return [view]
      
    } else if i == 1 {
      var imageProps = ImageProps()
      imageProps.backgroundColor = .blue
      imageProps.setKey(AppKeys.image)
      let image = Image(props: imageProps)
      
      var viewProps = ViewProps()
      viewProps.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
      viewProps.backgroundColor = .gray
      viewProps.children = [image]
      viewProps.setKey(AppKeys.container)
      let view = View(props: viewProps)
      
      return [view]
      
    } else {
      return []
    }
    
  }
  
  static func layout(views: ViewsContainer<AppKeys>, props: AppProps, state: EmptyState) -> Void {
    let container = views[.container]
    let image = views[.image]
    let innerView = views[.innerView]
    
    container?.size = .fixed(150, 150)
    image?.size = .fixed(150, 150)
    innerView?.size = .fixed(150, 150)
  }
}

fileprivate enum AppKeys: String {
  case container, image, innerView
}


fileprivate class WeakNode {
  weak var value: AnyNode?
  init(value: AnyNode) {
    self.value = value
  }
}

fileprivate class WeakView {
  weak var value: UIView?
  init(value: UIView) {
    self.value = value
  }
}

fileprivate func collectNodes(node: AnyNode) -> [AnyNode] {
  return (node.children.map { collectNodes(node: $0) }.reduce([], { $0 + $1 })) + node.children
}

fileprivate func collectView(view: UIView) -> [UIView] {
  return (view.subviews.map { collectView(view: $0) }.reduce([], { $0 + $1 })) + view.subviews
}
