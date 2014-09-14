;+
; NAME:
;    idlv4l2_stopcapture
;
; PURPOSE:
;    Stop the capture stream on a video4linux2 device
;
; CATEGORY:
;    Image acquisition, hardware interface
;
; CALLING SEQUENCE:
;    res = idlv4l2_stopcapture(stream)
;
; INPUT:
;    stream: IDLV4L2 structure describing a video capture stream
;
; OUTPUT:
;    res: 1 on success, 0 for failure.
;
; NOTE:
;    idlv4l2_stopcapture is called as needed by idlv4l2_close, and
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
; 02/16/2011 DGG documentation fixes.
;
; Copyright (c) 2011, David G. Grier
;-
function idlv4l2_stopcapture, s, debug = debug

COMPILE_OPT IDL2

debug = keyword_set(debug)

if ~isa(s, 'IDLV4L2') then $
   return, 1

if ~s.capturing then $
   return, 1

res = call_external("idlv4l2.so", "idlv4l2_stopcapture", $
                    /cdecl, debug, $
                    s.fd)

if ~res then begin
   message, "could not stop capture stream on "+s.device_name, /inf
   message, "closing "+s.device_name, /inf
   idlv4l2_close, s
   return, 0
endif

s.capturing = 0B

return, 1
end
