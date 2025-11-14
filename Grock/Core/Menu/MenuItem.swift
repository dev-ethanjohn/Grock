//
//  MenuItem.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/7/25.
//
import Foundation

//TODO: userdefaults/ or anything for offline persistence and access
struct MenuItem: Codable, Identifiable {
    var id = UUID().uuidString
    let title: String
    let iconName: String
    
    static let userSettingsMenuItems: [MenuItem] = [
        MenuItem(title: "Notification Settings", iconName: "bell"),
        MenuItem(title: "Account Settings", iconName: "person"),
        MenuItem(title: "Privacy Settings", iconName: "lock")
    ]
    
    static let feedbackMenuItems: [MenuItem] = [
        MenuItem(title: "Submit Issue", iconName: "exclamationmark.bubble"),
        MenuItem(title: "Share Idea", iconName: "lightbulb"),
        MenuItem(title: "Rate Us", iconName: "star")
    ]
//    MARK: Reiterate design 
//
    static let infoMenuItems: [MenuItem] = [
        MenuItem(title: "Privacy", iconName: "lock.shield"),
        MenuItem(title: "App Roadmap", iconName: "map"),
        MenuItem(title: "Help Center", iconName: "questionmark.circle"),
        MenuItem(title: "About Us", iconName: "info.circle")
    ]
}


