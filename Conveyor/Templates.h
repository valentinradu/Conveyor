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

NSString const *TemplateColorExtensionPaletteItem =
STRING (
    CWPalette(name: "%@", dic:[\n%@\n])
);

NSString const *TemplateColorExtensionDicItem =
STRING (
    "%@": UIColor(red: %@, green: %@, blue: %@, alpha: %@)
);

NSString const *TemplateColorExtensionLetItem =
STRING (
    let %@:UIColor
);

NSString const *TemplateColorExtensionInitItem =
STRING (
    self.%@ = dic["%@"]!
);

NSString const *TemplateColorExtension =
STRING (
    //This file was automatically generated with Conveyor Resource Manager. Manually modifying it is probably a bad idea."\n
    import UIKit\n
    class CWPalette: NSObject {\n
        static let availablePalettes = [\n%@\n]\n
        let name:String\n
        %@\n
        
        init(name:String, dic:[String:UIColor]) {\n
            self.name = name\n
            %@
        }\n
    }\n
);

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
        let %@ = NSBundle.mainBundle().localizedStringForKey("%@", value:"?", table:Optional.None)
);

NSString const *TemplateLocalizedStringsExtension =
STRING (
        //This file was automatically generated with Conveyor Resource Manager. Manually modifying it is probably a bad idea.\n
        import Foundation\n
        struct LocalizedStrings {\n
            %@\n
        }\n
        extension String {\n
            static var localized:LocalizedStrings {\n
                return LocalizedStrings()\n
            }\n
        }
);

#endif /* LocalizedStringsCSVTemplate_h */
