;+
; NAME:
;    v4lsnap
;
; PURPOSE:
;    Read an image from a video4linux2 device
;
; CATEGORY:
;    Image acquisition, hardware interface
;
; CALLING SEQUENCE:
;    a = v4lsnap([device_name])
;
; INPUT:
;    device_name: Name of the video4linux2 device.
;        Default: /dev/video0
;
; OUTPUTS:
;    a: image
;
; PROCEDURE:
;    Calls routines from the idlv4l2 library
;
; EXAMPLE:
;    IDL> a = v4lsnap()
;
; MODIFICATION HISTORY:
; 01/13/2011 Written by David G. Grier, New York University
;
; Copyright (c) 2011, David G. Grier
;-
function v4lsnap, dev = dev, debug = debug

COMPILE_OPT IDL2

if ~isa(dev, 'String') then $
   dev = '/dev/video0'

s = idlv4l2_open(dev, debug = debug)
a = idlv4l2_readframe(s, debug = debug)
idlv4l2_close, s, debug = debug

return, a
end
