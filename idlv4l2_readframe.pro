;+
; NAME:
;    idlv4l2_readframe
;
; PURPOSE:
;    Read a video frame from a video4linux2 device
;
; CATEGORY:
;    Image acquisition, hardware interface
;
; CALLING SEQUENCE:
;    a = idlv4l2_readframe(stream)
;
; INPUT:
;    stream: IDLV4L2 structure describing a video capture stream
;
; OUTPUTS:
;    a: image
;
; EXAMPLE:
;    IDL> s = idlv4l2_open()
;    IDL> a = idlv4l2_readframe(s)
;    IDL> idlv4l2_close, s
;    IDL> tvscl, a
;
; MODIFICATION HISTORY:
; 01/13/2011 Written by David G. Grier, New York University
; 02/16/2011 DGG Documentation fixes.
;
; Copyright (c) 2011, David G. Grier
;-
function idlv4l2_readframe, s, debug = debug

COMPILE_OPT IDL2

debug = keyword_set(debug)

if ~isa(s, 'IDLV4L2') then $
   return, 0

if ~s.initialized then begin
   res = idlv4l2_init(s, debug = debug)
   if ~res then $
      return, 0
endif

if ~s.capturing then begin
   res = idlv4l2_startcapture(s, debug = debug)
   if ~res then $
      return, 0
endif

a = bytarr(s.w, s.h, /nozero)

res = call_external("idlv4l2.so", "idlv4l2_readframe", $
                    /cdecl, debug, $
                    s.fd, $
                    a)

if ~res then begin
   message, "could not read image from "+s.device_name, /inf
   message, "closing "+s.device_name, /inf
   idlv4l2_close, s
   return, 0
endif

return, a
end
