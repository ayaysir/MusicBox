//
//  Typealiases.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/10/16.
//

import UIKit

typealias FileURLBlock = (_ url: URL?) -> Void
typealias ErrorBlock = (_ error: Error) -> ()

/// Here is the completion block
typealias FileCompletionBlock = () -> Void
var block: FileCompletionBlock?

typealias VoidBlock = () -> Void
typealias StringBlock = (_ string: String?) -> Void

let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
