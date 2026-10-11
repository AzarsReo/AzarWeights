//
//  Theme.swift
//  Reusable color palette extracted from TDEEArch
//
//  Drop this file into any SwiftUI project to reuse the color scheme.
//  Usage: .tint(.brandPurple), Color.appBackground, .background(Color.cardDarkGrey), etc.
//

import SwiftUI

extension Color {
    // MARK: - Core (the identity: black bg, grey cards, purple accent)
    static let appBackground = Color.black                               // base screen background
    static let brandPurple   = Color(red: 0.55, green: 0.18, blue: 0.85) // accent / tint
    static let cardDarkGrey  = Color(red: 0.13, green: 0.13, blue: 0.15) // card background
    static let midGrey       = Color(red: 0.22, green: 0.22, blue: 0.25) // borders / inactive
    static let lightGrey     = Color(red: 0.65, green: 0.65, blue: 0.68) // secondary text

    // MARK: - Macros
    static let macroProtein  = Color(red: 0.35, green: 0.65, blue: 1.00) // blue
    static let macroCarb     = Color(red: 0.95, green: 0.75, blue: 0.20) // gold
    static let macroFat      = Color(red: 0.95, green: 0.45, blue: 0.30) // orange-red

    // MARK: - Status / goals
    static let statusRed     = Color(red: 0.95, green: 0.25, blue: 0.25) // extreme deficit
    static let statusOrange  = Color(red: 0.95, green: 0.55, blue: 0.20) // intensive
    static let statusGold    = Color(red: 0.95, green: 0.75, blue: 0.20) // moderate
    static let statusTeal    = Color(red: 0.35, green: 0.80, blue: 0.65) // maingain
    static let statusGreen   = Color(red: 0.25, green: 0.75, blue: 0.45) // bulk
    static let accentGreen   = Color(red: 0.35, green: 0.80, blue: 0.45) // positive / fiber

    // MARK: - Micronutrient accents
    static let microCalcium   = Color(red: 0.55, green: 0.75, blue: 0.95)
    static let microIron      = Color(red: 0.90, green: 0.35, blue: 0.35)
    static let microMagnesium = Color(red: 0.65, green: 0.45, blue: 0.95)
    static let microZinc      = Color(red: 0.35, green: 0.65, blue: 0.65)
    static let microB12       = Color(red: 0.75, green: 0.35, blue: 0.85)
}
