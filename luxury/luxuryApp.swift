//
//  luxuryApp.swift
//  luxury
//
//  Created by Aditya Chauhan on 15/05/26.
//

import SwiftUI
import AppIntents

@main
struct luxuryApp: App {
    @State private var appCoordinator = AppCoordinator.shared
    @State private var saAppState = SalesAssociateAppState.shared
    @State private var bmAppState = BoutiqueManagerAppState()
    @State private var icAppState = InventoryControllerAppState()
    @State private var caAppState = CorporateAdminAppState()
    @State private var languageManager = LanguageManager.shared
    
    init() {
        let coordinator = AppCoordinator.shared
        let saState = SalesAssociateAppState.shared
        AppDependencyManager.shared.add(dependency: coordinator)
        AppDependencyManager.shared.add(dependency: saState)
        
        // Register App Intents / Siri Shortcuts
        RSMSAppShortcuts.updateAppShortcutParameters()
        
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(AppColors.background)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(AppColors.gold)
        
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(AppColors.background)
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        UIScrollView.appearance().showsVerticalScrollIndicator = false
        UIScrollView.appearance().showsHorizontalScrollIndicator = false
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appCoordinator)
                .environment(saAppState)
                .environment(bmAppState)
                .environment(icAppState)
                .environment(caAppState)
                .environment(languageManager)
                .environment(\.locale, languageManager.currentLocale)
                .id(languageManager.selectedLanguage)
                .preferredColorScheme(.dark)
                .task {
                    await CacheManager.shared.clearBucket("catalog")
                }
        }
    }
}

