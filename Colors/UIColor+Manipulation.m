//
//  UIColor+Manipulation.m
//  Colors
//
//  Created by Matt Zanchelli on 9/24/13.
//  Copyright (c) 2013 Matt Zanchelli. All rights reserved.
//

#import "UIColor+Manipulation.h"
#import "UIColor+Components.h"

#define SQUARED(X) ((X)*(X))

@implementation UIColor (Manipulation)

/*
+ (CGFloat)euclideanDistanceFromColor:(UIColor *)color
							  toColor:(UIColor *)anotherColor
{
	CGFloat y1 = color.yValue;
	CGFloat y2 = anotherColor.yValue;
	
	CGFloat u1 = color.uValue;
	CGFloat u2 = anotherColor.uValue;
	
	CGFloat v1 = color.vValue;
	CGFloat v2 = anotherColor.vValue;
	
	CGFloat distance = sqrtf(SQUARED(y1-y2) + SQUARED(u1-u2) + SQUARED(v1-v2));
	
	return distance;
}
*/

// CIE ΔE*ab (Delta E)
// Example outputs:
// White - Black: 116.000000
// White - Red:   114.558990
// White - Green: 120.415581
// White - Blue:  149.955170
// Blue  - Green: 258.693024
// Original colors gathered from RGB colorspace
+ (CGFloat)euclideanDistanceFromColor:(UIColor *)color
							  toColor:(UIColor *)anotherColor
{
	CGFloat l1 = color.CIELab_LValue;
	CGFloat l2 = anotherColor.CIELab_LValue;
	
	CGFloat a1 = color.CIELab_aValue;
	CGFloat a2 = anotherColor.CIELab_aValue;
	
	CGFloat b1 = color.CIELab_bValue;
	CGFloat b2 = anotherColor.CIELab_bValue;
	
	CGFloat distance = sqrtf(SQUARED(l1-l2) + SQUARED(a1-a2) + SQUARED(b1-b2));
	
	return distance;
}

double degrees(double x) {
	return x * (180 / M_1_PI);
}

double radians(double x) {
	return x * (M_1_PI / 180);
}

#pragma mark This returns NaN for Beatles white album
/// The perceived difference between two colors.
/// Calculated using the CIEDE2000 Color-Difference Formula.
+ (double)differenceBetweenColor:(UIColor *)color1 andColor:(UIColor *)color2
{
	// Modification of python algorithm https://github.com/gtaylor/python-colormath/blob/master/colormath/color_diff.py
	/*
	 Copyright (c) 2012, Greg Taylor
	 All rights reserved.
	 
	 Redistribution and use in source and binary forms, with or without modification,
	 are permitted provided that the following conditions are met:
	 
	 * Redistributions of source code must retain the above copyright notice, this
	 list of conditions and the following disclaimer.
	 * Redistributions in binary form must reproduce the above copyright notice,
	 this list of conditions and the following disclaimer in the documentation
	 and/or other materials provided with the distribution.
	 * Neither the name of the DUO Interactive, LLC nor the names of its
	 contributors may be used to endorse or promote products derived from this
	 software without specific prior written permission.
	 
	 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
	 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
	 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
	 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	 */
	
	// Default values
#warning should these be configurable?
	double Kl = 1.0f;
	double Kc = 1.0f;
	double Kh = 1.0f;
	
	// Color 1
	double L1 = color1.CIELab_LValue;
	double a1 = color1.CIELab_aValue;
    double b1 = color1.CIELab_bValue;
	
	// Color 2
    double L2 = color2.CIELab_LValue;
    double a2 = color2.CIELab_aValue;
    double b2 = color2.CIELab_bValue;
	
    double avg_Lp = (L1 + L2) / 2.0f;
	double C1 = sqrt(pow(a1, 2) + pow(b1, 2));
	double C2 = sqrt(pow(a2, 2) + pow(b2, 2));
    double avg_C1_C2 = (C1 + C2) / 2.0f;
	
    double G = 0.5f * (1.0f - sqrt(pow(avg_C1_C2 , 7.0f) / (pow(avg_C1_C2, 7.0f) + pow(25.0f, 7.0f))));
	
    double a1p = (1.0f + G) * a1;
    double a2p = (1.0f + G) * a2;
    double C1p = sqrt(pow(a1p, 2) + pow(b1, 2));
    double C2p = sqrt(pow(a2p, 2) + pow(b2, 2));
    double avg_C1p_C2p =(C1p + C2p) / 2.0f;
	
	double h1p;
	if ( degrees(atan2(b1,a1p)) >= 0 ) {
		h1p = degrees(atan2(b1,a1p));
	} else {
		h1p = degrees(atan2(b1,a1p)) + 360;
	}

	double h2p;
	if ( degrees(atan2(b2,a2p)) >= 0 ) {
		h2p = degrees(atan2(b2,a2p));
	} else {
		h2p = degrees(atan2(b2,a2p)) + 360;
	}

	double avg_Hp;
	if ( fabs(h1p - h2p) > 180 ) {
		avg_Hp = (h1p + h2p + 360) / 2.0f;
	} else {
		avg_Hp = (h1p + h2p) / 2.0f;
	}
	
	double T = 1 - 0.17 * cos(radians(avg_Hp - 30)) + 0.24f * cos(radians(2 * avg_Hp)) + 0.32f * cos(radians(3 * avg_Hp + 6)) - 0.2f  * cos(radians(4 * avg_Hp - 63));
	
	double diff_h2p_h1p = h2p - h1p;
	double delta_hp;
	if ( fabs(diff_h2p_h1p) <= 180 ) {
		delta_hp = diff_h2p_h1p;
	} else if ((fabs(diff_h2p_h1p) > 180) && (h2p <= h1p) ) {
		delta_hp = diff_h2p_h1p + 360;
	} else {
		delta_hp = diff_h2p_h1p - 360;
	}
	
	double delta_Lp = L2 - L1;
	double delta_Cp = C2p - C1p;
	double delta_Hp = 2 * sqrt(C2p * C1p) * sin(radians(delta_hp) / 2.0);

	double S_L = 1 + ((0.015f * pow(avg_Lp - 50, 2)) / sqrt(20 + pow(avg_Lp - 50, 2.0f)));
	double S_C = 1 + 0.045f * avg_C1p_C2p;
	double S_H = 1 + 0.015f * avg_C1p_C2p * T;

	double delta_ro = 30 * exp(-(pow(((avg_Hp - 275) / 25), 2.0f)));
	double R_C = sqrt((pow(avg_C1p_C2p, 7.0f)) / (pow(avg_C1p_C2p, 7.0f) + pow(25.0f, 7.0f)));
	double R_T = -2 * R_C * sin(2 * radians(delta_ro));

	double delta_E = sqrt(pow(delta_Lp /(S_L * Kl), 2) + pow(delta_Cp /(S_C * Kc), 2) + pow(delta_Hp /(S_H * Kh), 2) + R_T * (delta_Cp /(S_C * Kc)) * (delta_Hp / (S_H * Kh)));
	
	return delta_E;
}

@end
