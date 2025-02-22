//
//  AdMananger.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/22.
//

import Foundation

struct AdManager {
  private init() {}
  
  // ====== 광고 ====== //
  /// 내부 테스트용 변수: true인 경우 광고 내보냄
  static private let productMode: Bool = {
#if DEBUG
    true
#else
    true
#endif
  }()
  
  /// 인앱 구입 여부
  static var isPurchasedRemoveAD: Bool {
    InAppProducts.helper.isProductPurchased(InAppProducts.productIDs[0])
  }
  
  /// 최종 광고 표시 여부
  static var isReallyShowAd: Bool {
    productMode && !isPurchasedRemoveAD
  }
}
