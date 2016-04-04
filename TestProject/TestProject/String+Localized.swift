import Foundation
 struct LocalizedStrings {
 let secondString = [[NSBundle mainBundle] localizedStringForKey:("second_string") value:@"" table:((void *)0)]
let fourthString = [[NSBundle mainBundle] localizedStringForKey:("fourth_string") value:@"" table:((void *)0)]
let firstString = [[NSBundle mainBundle] localizedStringForKey:("first_string") value:@"" table:((void *)0)]
 }
 extension String {
 static var localized:LocalizedStrings {
 return LocalizedStrings()
 }
 }