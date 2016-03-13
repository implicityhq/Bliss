//
//  Helpers.swift
//  Bliss
//
//  Created by Jason Silberman on 3/7/16.
//  Copyright © 2016 Implicity. All rights reserved.
//

import UIKit

// MARK: - Helpers

extension Bliss {
	class Helpers {
		class func navigationBarHeight(theme: Bliss.Theme) -> CGFloat {
			if !theme.barVisible {
				return 0
			} else if theme.statusBarVisible && theme.placement == .Top {
				return Constants.navigationBarHeight + Constants.statusBarHeight
			} else if theme.barVisible {
				return Constants.navigationBarHeight
			} else {
				return 0
			}
		}
	}
}