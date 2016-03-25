//
//  LocalizedStringsCSVTemplate.h
//  Conveyor
//
//  Created by Valentin Radu on 23/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

#ifndef LocalizedStringsCSVTemplate_h
#define LocalizedStringsCSVTemplate_h
#import "Macros.h"
#import <Foundation/Foundation.h>

NSString const *TemplateLocalizedStringsCSVItem =
STRING (
%@;%@
);

NSString const *TemplateLocalizedStringsCSV =
STRING (
"Key";%@\r\n%@
);

NSString const *TemplateLocalizedStringsExtensionItem =
STRING (
    let %@ = NSLocalizedString("%@", comment: "")
);

NSString const *TemplateLocalizedStringsExtension =
STRING (
        //This file was automatically generated with Conveyor Resource Manager. Manually modifying it is probably a bad idea.",
        import Foundation
        struct LocalizedStrings {
            %@
        }
        extension String {
            static var localized:LocalizedStrings {
                return LocalizedStrings()
            }
        }
);

#endif /* LocalizedStringsCSVTemplate_h */
