//
//  Router.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import Observation

struct PresentedRoute: Identifiable, Hashable {
    let value: AnyHashable
    
    var id: Int {
        value.hashValue
    }
    
    init<T: Hashable>(_ route: T) {
        value = AnyHashable(route)
    }
}

@Observable
final class Router {
    var path = NavigationPath()
    var presentedSheet: PresentedRoute?
    var presentedFullScreen: PresentedRoute?
    
    func push<T: Hashable>(_ route: T) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func presentSheet<T: Hashable>(_ route: T) {
        presentedSheet = PresentedRoute(route)
    }
    
    func presentFullScreen<T: Hashable>(_ route: T) {
        presentedFullScreen = PresentedRoute(route)
    }
    
    func dismissModal() {
        presentedSheet = nil
        presentedFullScreen = nil
    }
}
