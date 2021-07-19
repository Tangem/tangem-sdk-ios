//
//  CompletionResult.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public typealias CompletionResult<T> = (Result<T, TangemSdkError>) -> Void
