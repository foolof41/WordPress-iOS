/*
 * StatsBarGraphCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@interface StatsViewsVisitorsBarGraphCell : WPTableViewCell

+ (CGFloat)heightForRow;

- (void)setGraphData:(NSDictionary *)graphData;

@end
