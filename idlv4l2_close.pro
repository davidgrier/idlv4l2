;+
; NAME:
;    idlv4l2_close
;
; PURPOSE:
;    Close a video capture stream on a video4linux2 device
;
; CATEGORY:
;    Image acquisition, hardware interface
;
; CALLING SEQUENCE:
;    idlv4l2_open, stream
;
; INPUTS:
;    stream: IDLV4L2 structure returned by idlv4l2_open
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
pro idlv4l2_close, s, debug = debug

COMPILE_OPT IDL2

debug = keyword_set(debug)

if ~isa(s, 'IDLV4L2') then $
   return

if s.capturing then $
   res = idlv4l2_stopcapture(s, debug = debug)

if s.initialized then $
   idlv4l2_uninit, s, debug = debug

res = call_external("idlv4l2.so", "idlv4l2_close", $
                    /cdecl, debug, $
                    s.fd)

if ~res then $
   message, "Error closing " + s.device_name, /inf

s = -1

end
