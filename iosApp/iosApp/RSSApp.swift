//
//  App.swift
//  iosApp
//
//  Created by Ekaterina.Petrova on 13.11.2020.
//  Copyright © 2020 orgName. All rights reserved.
//

import Foundation
import SwiftUI
import RssReader

@main
struct RSSApp: App {
    let rss: core.RssReader
    let store: ObservableFeedStore
    
    init() {
        rss = core.create(core.RssReader.Companion.shared, withLog: true)
        store = ObservableFeedStore(store: app.FeedStore(rssReader: rss))
    }
  
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
        }
    }
}

class ObservableFeedStore: ObservableObject {
    @Published public var state: app.FeedState = app.FeedState(progress: false, feeds: [], selectedFeed: nil)
    @Published public var sideEffect: app.FeedSideEffect?
    
    let store: app.FeedStore
    
    var stateWatcher : core.Closeable?
    var sideEffectWatcher : core.Closeable?

    init(store: app.FeedStore) {
        self.store = store
        stateWatcher = app.watchState(store).watch { [self] state in
            self.state = state as! app.FeedState
        }
        sideEffectWatcher = app.watchSideEffect(store).watch { [self] state in
            self.sideEffect = state as! app.FeedSideEffect
        }
    }
    
    public func dispatch(_ action: app.FeedAction) {
        store.dispatch(action: action)
    }
    
    deinit {
        stateWatcher?.close()
        sideEffectWatcher?.close()
    }
}

public typealias DispatchFunction = (app.FeedAction) -> ()

public protocol ConnectedView: View {
    associatedtype Props
    associatedtype V: View
    
    func map(state: app.FeedState, dispatch: @escaping DispatchFunction) -> Props
    func body(props: Props) -> V
}

public extension ConnectedView {
    func render(state: app.FeedState, dispatch: @escaping DispatchFunction) -> V {
        let props = map(state: state, dispatch: dispatch)
        return body(props: props)
    }
    
    var body: StoreConnector<V> {
        return StoreConnector<V>(content: render)
    }
}

public struct StoreConnector<V: View>: View {
    @EnvironmentObject var store: ObservableFeedStore
    let content: (app.FeedState, @escaping DispatchFunction) -> V
    
    public var body: V {
        return content(store.state, store.dispatch)
    }
}

