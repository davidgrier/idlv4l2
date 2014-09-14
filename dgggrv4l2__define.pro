;+
; NAME:
;    DGGgrV4L2
;
; PURPOSE:
;    Object for acquiring a frame-by-frame sequence of images
;    from a video4linux2 video source, which subclasses from 
;    the IDLgrModel class.
;
; CATEGORY:
;    Multimedia, object graphics
;
; CALLING SEQUENCE:
;    To initially create:
;        oVideo = obj_new('DGGgrV4L2')
;
;    To retrieve next image in video sequence
;        oVideo->Snap
;
; PROCEDURE:
;     Calls routines from the IDLV4L2 interface to the libv4l
;     user space library.
;
; MODIFICATION HISTORY:
; Based on DGGgrVideo
; 12/30/2010: Written by David G. Grier, New York University
; 01/11/2010: DGG Added DGGgrVideo::Snap() function
; 01/13/2010: DGG adapted from DGGgrVideo
;
; Copyright (c) 2010-2011 David G. Grier
;
;-

;;;;;
;
; DGGgrV4L2::Snap()
;
; Returns a picture without updating internal image.
;
function DGGgrV4L2::Snap

COMPILE_OPT IDL2, HIDDEN

a = idlv4l2_readframe(*self.stream, debug = self.debug)
return, a
end

;;;;;
;
; DGGgrV4L2::Snap
;
; Transfers a picture to the image
;
pro DGGgrV4L2::Snap

COMPILE_OPT IDL2, HIDDEN

a = idlv4l2_readframe(*self.stream, debug = self.debug)
if n_elements(a) gt 1 then $
   self.image->setproperty, data = a, /no_copy
end

;;;;;
;
; DGGgrV4L2::GetProperty
;
; Get the properties of the video, its underlying
; IDLgrModel object, or its component IDLgrImage object.
;
pro DGGgrV4L2::GetProperty, geometry = geometry, $
                            _ref_extra = re

COMPILE_OPT IDL2, HIDDEN

self->IDLgrModel::GetProperty, _extra = re

self.image->getproperty, _extra = re

geometry = self.geometry

end

;;;;;
;
; DGGgrV4L2::Cleanup
;
; Close the video stream, 
;
pro DGGgrV4L2::Cleanup

COMPILE_OPT IDL2, HIDDEN

idlv4l2_close, *self.stream, debug = self.debug
ptr_free, self.stream

end

;;;;;
;
; DGGgrV4L2::Init
;
; Initialize the DGGgrV4L2 object:
; Open the video stream
; Define an image object
; Add the image to the underlying IDLgrModel
;
function DGGgrV4L2::Init, device_name = device_name, $
                          geometry = geometry, $
                          debug = debug, $
                          _extra = e

COMPILE_OPT IDL2, HIDDEN

if (self->IDLgrModel::Init(_extra = e) ne 1) then $
   return, 0

if ~isa(device_name, 'String') then $
   device_name = "/dev/video0"

self.debug = keyword_set(debug)

s = idlv4l2_open(device_name, debug = self.debug)

if ~isa(s, 'IDLV4l2') then $
   return, 0

self.stream = ptr_new(s)

a = idlv4l2_readframe(*self.stream, debug = self.debug)

if n_elements(a) le 1 then $
   return, 0

self.geometry = [(*self.stream).w, (*self.stream).h]

self.image = IDLgrImage(a, order = 1)
self->add, self.image

return, 1
end

;;;;;
;
; DGGgrV4L2__define
;
; Define the DGGgrV4L2 object
;
pro DGGgrV4L2__define

COMPILE_OPT IDL2

struct = {DGGgrV4L2, $
          inherits IDLgrModel, $
          image:    obj_new(), $
          stream:   ptr_new(), $
          geometry: [0L, 0],   $
          debug: 0 $
         }
end
