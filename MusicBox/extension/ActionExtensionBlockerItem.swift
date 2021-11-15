//
//  ActionExtensionBlockerItem.swift
//  MusicBox
//
//  Created by https://pspdfkit.com/blog/2016/hiding-action-share-extensions-in-your-own-apps/
//

import UIKit

class ActionExtensionBlockerItem: NSObject, UIActivityItemSource {
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "com.your.unique.uti.here";
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // Returning an NSObject here is safest, because otherwise it is possible for the activity item to actually be shared!
        return NSObject()
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return nil
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
}
