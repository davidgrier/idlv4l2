;+
; NAME:
;    idlv4l2_init
;
; PURPOSE:
;    Initialize memory-mapped frame transfers for a video4linux2 device
;
; CATEGORY:
;    Image acquisition, hardware interface
;
; CALLING SEQUENCE:
;    res = idlv4l2_init(stream)
;
; INPUT:
;    stream: IDLV4L2 structure describing a video capture stream
;
; OUTPUTS:
;    res: 1: success, 0: failure
;
; NOTE:
;    idlv4l2_init is called as needed by idlv4l2_readframe, and
;    need not be called independently.
;
; EXAMPLE:
;    IDL> s = idlv4l2_open()
;    IDL> a = idlv4l2_readframe(s)
;    IDL> idlv4l2_close, s
;    IDL> tvscl, a
;
; MODIFICATION HISTORY:
; 01/13/2011 Written by David G. Grier, New York University
;
; Copyright (c) 2011 David G. Grier
;-
function idlv4l2_init, s, debug = debug

COMPILE_OPT IDL2

debug = keyword_set(debug)

if ~isa(s, 'IDLV4L2') then $
   return, 0

s.initialized = 0B

w = 0L
h = 0L
res = call_external("idlv4l2.so", "idlv4l2_init", /cdecl, debug, $
                    s.fd, w, h)

if ~res then begin
   message, "could not initialize " + s.device_name, /inf
   message, "closing " + s.device_name, /inf
   idlv4l2_close, s
   return, 0
endif

s.w = w
s.h = h
s.initialized = 1B

return, 1
end
