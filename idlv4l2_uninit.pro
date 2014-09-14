;+
; NAME:
;    idlv4l2_uninit
;
; PURPOSE:
;    Free resources allocated for a capture stream on a video4linux2 device
;
; CATEGORY:
;    Image acquisition, hardware interface
;
; CALLING SEQUENCE:
;    idlv4l2_uninit, stream
;
; INPUT:
;    stream: IDLV4L2 structure describing a video capture stream
;
; NOTE:
;    idlv4l2_uninit is called as needed by idlv4l2_close, and
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
pro idlv4l2_uninit, s, debug = debug

COMPILE_OPT IDL2

debug = keyword_set(debug)

if ~isa(s, 'IDLV4L2') then $
   return

if ~s.initialized then $
   return

if s.capturing then begin
   res = idlv4l2_stopcapture(s, debug = debug)
   if ~res then $
      return
endif

res = call_external("idlv4l2.so", "idlv4l2_uninit", $
                    /cdecl, debug, $
                    s.fd)

s.initialized = 0B

end
