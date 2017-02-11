
#ifndef __PROTO_H__
#define __PROTO_H__

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

// Public Interfaces

// -1 when request receive-parse error
//  0 if nothing considerable has changed
//  1 when valid request received
i8   proto_try_read_request ( Byte* buffer, u16 *len, u16 max_size );
void proto_send_reply       ( u8 *buffer, u16 length );
void proto_send_error_reply ( u8 code );


#ifdef __cplusplus
}
#endif


#endif  // __PROTO_H__
