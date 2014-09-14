;+
; NAME:
;    idlv4l2_startcapture
;
; PURPOSE:
;    Start the capture stream on a video4linux2 device
;
; CATEGORY:
;    Image acquisition, hardware interface
;
; CALLING SEQUENCE:
;    res = idlv4l2_startcapture(stream)
;
; INPUT:
;    stream: IDLV4L2 structure describing a video capture stream
;
; OUTPUTS:
;    res: IDLV4L2 structure describing the video capture stream
;
; NOTE:
;    idlv4l2_startcapture is called as needed by idlv4l2_readframe, and
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
function idlv4l2_startcapture, s, debug = debug

COMPILE_OPT IDL2

debug = keyword_set(debug)

if ~isa(s, 'IDLV4L2') then $
   return, 0

if s.capturing then $
   return, 1

if ~s.initialized then begin
   res = idlv4l2_init(s, debug = debug)
   if ~res then $
      return, 0
endif
   
res = call_external("idlv4l2.so", "idlv4l2_startcapture", $
                    /cdecl, debug, $
                    s.fd)

if ~res then begin
   message, "could not start capture stream on "+s.device_name, /inf
   message, "closing "+s.device_name, /inf
   idlv4l2_close, s
   return, 0
endif

s.capturing = 1B

return, 1
end
