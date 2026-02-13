//
//  MenuItem.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/7/25.
//
import Foundation

struct MenuItem: Codable, Identifiable {
    var id = UUID().uuidString
    let title: String
    let iconName: String
}

