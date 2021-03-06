//
//  Typealiases.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/16.
//

import UIKit
import Firebase

typealias FileURLBlock = (_ url: URL?) -> Void
typealias ErrorBlock = (_ error: Error) -> ()

/// Here is the completion block
typealias FileCompletionBlock = () -> Void
var block: FileCompletionBlock?

typealias VoidBlock = () -> Void
typealias StringBlock = (_ string: String?) -> Void

typealias RefHandler = (_ targetPostLikesRef: DatabaseReference, _ currentUID: String) -> ()

let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)

/// 배너 광고 높이
let adBannerHeight: CGFloat = 50
