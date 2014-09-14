;+
; NAME:
;    idlv4l2_open
;
; PURPOSE:
;    Open a video capture stream on a video4linux2 device
;
; CATEGORY:
;    Image acquisition, hardware interface
;
; CALLING SEQUENCE:
;    stream = idlv4l2_open([device_name])
;
; OPTIONAL INPUTS:
;    device_name: Name of the video capture device.
;        Default: /dev/video0
;
; OUTPUTS:
;    stream: IDLV4L2 structure describing the video capture stream
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
; Copyright (c) 2011, David G. Grier
;-
function idlv4l2_open, device_name, debug = debug

COMPILE_OPT IDL2

debug = keyword_set(debug)

fd = -1L

if n_params() eq 0 then $
   device_name = '/dev/video0'  ; default to first video device
if ~isa(device_name, 'String') then begin
   message, 'usage: idlv4l2_open, device_name', /inf
   return, -1
endif

res = call_external("idlv4l2.so", "idlv4l2_open", $
                    /cdecl, debug, $
                    device_name, $
                    fd)

if (res) then begin
   s = {IDLV4L2, $
        device_name: device_name, $
        fd: fd, $               ; file descriptor
        w: 0L, $                ; image width
        h: 0L, $                ; image height
        initialized: 0B, $      ; 1 if memory is mapped
        capturing: 0B $         ; 1 if capture stream has been started
       }
   return, s
endif

return, -1
end
