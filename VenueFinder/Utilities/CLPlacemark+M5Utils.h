//  CLPlacemark+Utils.h
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import <CoreLocation/CoreLocation.h>

// Utilities to generate friendly descriptions of CLPlacemark information.

@interface CLPlacemark (M5Utils)

// The best guess at the street address for this placemark, or nil if it seems
// to have no data related to a street address.
@property (nonatomic, readonly) NSString *streetAddress;

// The best guess at the most salient information to describe this placemark
// (e.g. its name, or else its street address, or else its locality, and so on).
// Returns nil if there is no human-readable description of the placemark available.
// Intended to be used with friendlySubtitle in a cell or map pin, for instance.
@property (nonatomic, readonly) NSString *friendlyTitle;

// The best guess at the most salient supplementary information to describe this placemark.
// This string should have no overlap with the information in friendlyTitle; the two
// are intended to be used together in a cell or map pin, for instance.
// Returns nil if there is no human-readable information of the placemark, with the
// possible exception of that in friendlyTitle.
@property (nonatomic, readonly) NSString *friendlySubtitle;

@end
