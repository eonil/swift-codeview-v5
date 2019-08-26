//
//  IMPLString.swift
//  CodeView5
//
//  Created by Henry on 2019/07/31.
//  Copyright © 2019 Eonil. All rights reserved.
//

import Foundation

/// A wrapper of text data source that acts as an `NSString`.
///
/// This exists to support `NSTextInputClient` that requires
/// access to underlying `NSString`.
///
/// Underlying text data source fully UTF-8 based with
/// cached UTF-16 indices at some points. 
///
final class IMPLString: NSString {

}
