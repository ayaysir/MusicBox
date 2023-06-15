//
//  MusicBoxProducts.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/23.
//

import Foundation
import StoreKit

struct MusicBoxProducts {
    
    public static let SwiftShopping = IAPInfo.iapProductID
    private static let productIdentifiers: Set<ProductIdentifier> = [MusicBoxProducts.SwiftShopping]
    public static let store = IAPHelper(productIds: MusicBoxProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
