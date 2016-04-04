//
//  Macros.h
//  Conveyor
//
//  Created by Valentin Radu on 23/03/16.
//  Copyright © 2016 Valentin Radu. All rights reserved.
//

#ifndef Macros_h
#define Macros_h

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define STRING(text) @ STRINGIZE2(text)
#define EMPTY_MACRO
#define DEFER(id) id EMPTY_MACRO

#endif /* Macros_h */
