;+
; NAME:
;    IDLv4l2
;
; PURPOSE:
;    Pure IDL interface to media devices supported by the
;    Video4Linux2 API, including video cameras.  Currently,
;    only video capture devices are supported.
;
; PROPERTIES:
; I: Can be set during initialization
; G: Can be read with GetProperty
; S: Can be set with SetProperty
;
; [IG ] device_name: string name of device's interface.
;       Default: /dev/video0
; [IGS] dimensions: [width, height] of image
; [ GS] width: width of image [pixels]
; [ GS] height: height of image [pixels]
; [IGS] greyscale: flag -- if set, return greyscale image
; [IGS] hflip: flag -- if set, flip images horizontally
; [IGS] vflip: flag -- if set, flip images vertically
;
; [ G ] data: image data
; [ G ] capabilities: structure describing device capabilities
; [ G ] format: image format
; [ GS] input: index of input channel
; [ G ] input_properties: properties of current input channel
; [ G ] fd: file descriptor of open device
;
; METHODS:
; IDLv4l2::GetProperty, property=value
;
; IDLv4l2::SetProperty, property=value
;
; IDLv4l2::Read()
;    Read next image from source.
;
; EXAMPLE:
; IDL> a = idlv4l2()
; IDL> tvscl, a.read()
;
; REFERENCES:
; 1. Linux Media Infrastructure API
;    http://linuxtv.org/downloads/v4l-dvb-apis/
;
; 2. Video for Linux Two header file:
;    /usr/include/linux/videodev2.h
;
; MODIFICATION HISTORY:
; 06/04/2015 Written by David G. Grier, New York University
;
; Copyright (c) 2015 David G. Grier
;-

;;;;;
;
; idlv4l2::Read()
;
function idlv4l2::Read

  COMPILE_OPT IDL2, HIDDEN

  self.read
  return, (self.doconvert) ? *self._rgb : *self._data
end

;;;;;
;
; idlv4l2::Read
;
pro idlv4l2::Read

  COMPILE_OPT IDL2, HIDDEN

  readu, self.fd, *self._data

  ;;; perform basic data conversions that are not handled
  ;;; by the driver
  if self.doconvert then begin
     self.yuv422_rgb
     if self.doflip then begin
        if self.hflip then $
           *self._rgb = reverse(*self._rgb, 2, /overwrite)
        if self.vflip then $
           *self._rgb = reverse(*self._rgb, 3, /overwrite)
     endif
  endif else begin
     if self.doflip then $
        *self._data = rotate(temporary(*self._data), $
                             (5*self.hflip + 7*self.vflip) mod 10)
  endelse
end

;;;;;
;
; idlv4l2::YUV422_RGB()
;
pro idlv4l2::YUV422_RGB

  COMPILE_OPT IDL2, HIDDEN

  yuv = float(*self._data)
  Y1 = 1.164 * (yuv[0:*:4, *] - 16.)
  Cr = yuv[1:*:4, *] - 128.
  Y2 = 1.164 * (yuv[2:*:4, *] - 16.)
  Cb = 0.391 * (yuv[3:*:4, *] - 128.)

  rgb = *self._rgb
  rgb[0, 0:*:2, *] = byte(((Y1 + 1.596 * Cr) > 0) < 255)
  rgb[1, 0:*:2, *] = byte(((Y1 - 0.813 * Cr - Cb) > 0) < 255)
  rgb[2, 0:*:2, *] = byte(((Y1 + 2.115 * Cr) > 0) < 255)
  rgb[0, 1:*:2, *] = byte(((Y2 + 1.596 * Cr) > 0) < 255)
  rgb[1, 1:*:2, *] = byte(((Y2 - 0.813 * Cr - Cb) > 0) < 255)
  rgb[2, 1:*:2, *] = byte(((Y2 + 2.115 * Cr) > 0) < 255)

  self._rgb = ptr_new(rgb, /no_copy)
end

;;;;;
;
; idlv4l2::ioctl
;
pro idlv4l2::ioctl, request, data, error = error

  COMPILE_OPT IDL2, HIDDEN

  error = ioctl(self.fd, self.id[request], data, /suppress_error)
end
  
;;;;;
;
; idlv4l2::BitSet()
;
function idlv4l2::BitSet, value, bit

  COMPILE_OPT IDL2, HIDDEN

  return, byte((value and bit) eq bit)
end

;;;;;
;
; idlv4l2::GetFmt()
;
function idlv4l2::GetFmt

  COMPILE_OPT IDL2, HIDDEN

  pix = {v4l2_pix_format, $
         width: 0UL, $
         height: 0UL, $
         pixelformat: bytarr(4), $
         field: 0UL, $
         bytesperline: 0UL, $
         sizeimage: 0UL, $
         colorspace: 0UL, $
         priv: 0UL, $
         flags: 0UL, $
         ycbcr_enc: 0UL, $
         quantization: 0UL $
        }

  fmt = {v4l2_format, $
         type: 1UL, $
         pad: 1UL, $
         fmt: pix, $
         raw_data: bytarr(200) $
        }

  self.ioctl, 'VIDIOC_G_FMT', fmt
  
  return, fmt
end

;;;;;
;
; idlv4l2_SetFormat()
;
pro idlv4l2::SetFormat, width = width, $
                        height = height, $
                        pixel_format = pixel_format, $
                        greyscale = greyscale, $
                        color = color

  COMPILE_OPT IDL2, HIDDEN

  fmt = self.getfmt()

  if isa(width, /number, /scalar) then $
     fmt.fmt.width = ulong(width)

  if isa(height, /number, /scalar) then $
     fmt.fmt.height = ulong(height)

  if (isa(pixel_format, 'string') && $
      (strlen(pixel_format) eq 4)) then $
         fmt.fmt.pixelformat = byte(strupcase(pixel_format))

  if isa(greyscale, /number, /scalar) then $
     fmt.fmt.pixelformat = byte(keyword_set(greyscale) ? 'GREY' : 'YUYV')

  if isa(color, /number, /scalar) then $
     fmt.fmt.pixelformat = byte(keyword_set(color) ? 'YUYV' : 'GREY')

  self.ioctl, 'VIDIOC_S_FMT', fmt
  
  fmt = self.getfmt()
  self.doconvert = strcmp(string(fmt.fmt.pixelformat), 'YUYV')
end

;;;;;
;
; idlv4l2_GetFormat()
;
function idlv4l2::GetFormat

  COMPILE_OPT IDL2, HIDDEN

  fmt = self.getfmt()
  
  ;;; enum v4l2_field
  case fmt.fmt.field of
     0: field = 'Any'
     1: field = 'None'
     2: field = 'Top/Odd'
     3: field = 'Bottom/Even'
     4: field = 'Interlaced'
     5: field = 'Sequential: Top/Bottom'
     6: field = 'Sequential: Bottom/Top'
     7: field = 'Alternate'
     8: field = 'Interlaced: Top/Bottom'
     9: field = 'Interlaced: Bottom/Top'
     else: field = 'Unknown: ' + fmt.fmt.field
  endcase
  
  idlfmt = {width: fmt.fmt.width, $
            height: fmt.fmt.height, $
            pixelformat: string(fmt.fmt.pixelformat), $
            field: field, $
            bytesperline: fmt.fmt.bytesperline, $
            sizeimage: fmt.fmt.sizeimage $
           }

  return, idlfmt
end

;;;;;
;
; idlv4l2::ListControls()
;
function idlv4l2::ListControls

  COMPILE_OPT IDL2, HIDDEN

  controls = hash()
  for id = 0, 43 do begin
     qc = self.querycontrol(id)
     if ~qc.flags.disabled then $
        controls[qc.name] = id
  endfor

  return, controls
end

;;;;;
;
; idlv4l2::QueryControl()
;
function idlv4l2::QueryControl, _id

  COMPILE_OPT IDL2, HIDDEN

  V4L2_CID_BASE   = '980900'XUL
  id = ulong(_id) + V4L2_CID_BASE

  qc = {v4l2_queryctrl, $
        id: id, $
        type: 0UL, $
        name: bytarr(32), $
        minimum: 0L, $
        maximum: 0L, $
        step: 0L, $
        default_value: 0L, $
        flags: 0UL, $
        reserved: [0UL, 0] $
       }

  self.ioctl, 'VIDIOC_QUERYCTRL', qc, error = error

  case qc.type of
     1: type = 'Integer'
     2: type = 'Boolean'
     3: type = 'Menu'
     4: type = 'Button'
     5: type = 'Integer64'
     6: type = 'Control Class'
     7: type = 'String'
     8: type = 'Bitmask'
     9: type = 'Integer Menu'
     '100'X: type = 'U8'
     '101'X: type = 'U16'
     '102'X: type = 'U32'
     else: type = 'Unknown: ' + string(qc.type)
  endcase
  
  flags = {disabled:         self.bitset(qc.flags,   '1'X) or error, $
           grabbed:          self.bitset(qc.flags,   '2'X), $
           read_only:        self.bitset(qc.flags,   '4'X), $
           update:           self.bitset(qc.flags,   '8'X), $
           inactive:         self.bitset(qc.flags,  '10'X), $
           slider:           self.bitset(qc.flags,  '20'X), $
           write_only:       self.bitset(qc.flags,  '40'X), $
           volatile:         self.bitset(qc.flags,  '80'X), $
           has_payload:      self.bitset(qc.flags, '100'X), $
           execute_on_write: self.bitset(qc.flags, '200'X)  $
          }
  
  idlqc = {id: qc.id - V4L2_CID_BASE, $
           type: type, $
           name: string(qc.name), $
           minimum: qc.minimum, $
           maximum: qc.maximum, $
           step: qc.step, $
           flags: flags}

  return, idlqc
end

;;;;;
;
; idlv4l2::SetControl
;
pro idlv4l2::SetControl, id, value

  COMPILE_OPT IDL2, HIDDEN

  qc = self.querycontrol(id)

  if qc.flags.disabled || qc.flags.inactive then begin
     message, 'Control not available', /inf
     return
  endif
  
  if value lt qc.minimum || value gt qc.maximum then begin
     message, 'Value out of range', /inf
     return
  endif
  
  V4L2_CID_BASE = '980900'XUL

  control = {v4l2_control, $
             id: ulong(id) + V4L2_CID_BASE, $
             value: long(value) $
            }

  self.ioctl, 'VIDIOC_S_CTRL', control
end

;;;;;
;
; idlv4l2::GetControl()
;
function idlv4l2::GetControl, id

  COMPILE_OPT IDL2, HIDDEN

  control = {v4l2_control, $
             id: ulong(id), $
             value: 0L $
            }
  
  self.ioctl, 'VIDIO_G_CTRL', control

  return, control.value
end

;;;;;
;
; idlv4l2::GetInput()
;
function idlv4l2::GetInput

  COMPILE_OPT IDL2, HIDDEN

  index = 0
  self.ioctl, 'VIDIOC_G_INPUT', index

  return, index
end

;;;;;
;
; idlv4l2::SetInput()
;
pro idlv4l2::SetInput, index

  COMPILE_OPT IDL2, HIDDEN

  if ~isa(index, /scalar, /number) then $
     return
  
  ndx = long(index)
  self.ioctl, 'VIDIOC_S_INPUT', ndx
end

;;;;;
;
; idlv4l2::GetInputProperties()
;
function idlv4l2::GetInputProperties

  COMPILE_OPT IDL2, HIDDEN

  input = {v4l2_input, $
           index: 0UL, $
           name: bytarr(32), $
           type: 0UL, $
           audioset: 0UL, $
           tuner: 0UL, $
           v4l2_std_id: 0ULL, $
           status: 0UL, $
           capabilities: 0UL, $
           reserved: ulonarr(3) $
           }

  self.ioctl, 'VIDIOC_ENUMINPUT', input

  id = input.v4l2_std_id
  std = {pal_b:       self.bitset(id,       '1'XUL), $
         pal_b1:      self.bitset(id,       '2'XUL), $
         pal_g:       self.bitset(id,       '4'XUL), $
         pal_h:       self.bitset(id,       '8'XUL), $
         pal_i:       self.bitset(id,      '10'XUL), $
         pal_d:       self.bitset(id,      '20'XUL), $
         pal_d1:      self.bitset(id,      '40'XUL), $
         pal_k:       self.bitset(id,      '80'XUL), $
         pal_m:       self.bitset(id,     '100'XUL), $
         pal_n:       self.bitset(id,     '200'XUL), $
         pal_nc:      self.bitset(id,     '400'XUL), $
         pal_60:      self.bitset(id,     '800'XUL), $
         ntsc_m:      self.bitset(id,    '1000'XUL), $
         ntsc_m_jp:   self.bitset(id,    '2000'XUL), $
         ntsc_433:    self.bitset(id,    '4000'XUL), $
         ntsc_m_kr:   self.bitset(id,    '8000'XUL), $
         secam_b:     self.bitset(id,   '10000'XUL), $
         secam_d:     self.bitset(id,   '20000'XUL), $
         secam_g:     self.bitset(id,   '40000'XUL), $
         secam_h:     self.bitset(id,   '80000'XUL), $
         secam_k:     self.bitset(id,  '100000'XUL), $
         secam_k1:    self.bitset(id,  '200000'XUL), $
         secam_l:     self.bitset(id,  '400000'XUL), $
         secam_lc:    self.bitset(id,  '800000'XUL), $
         atsc_8_vsb:  self.bitset(id, '1000000'XUL), $
         atsc_16_vsb: self.bitset(id, '2000000'XUL)  $
        }
  
  status = {no_power:    self.bitset(input.status,       '1'XUL), $
            no_signal:   self.bitset(input.status,       '2'XUL), $
            no_color:    self.bitset(input.status,       '4'XUL), $
            hflip:       self.bitset(input.status,      '10'XUL), $
            vflip:       self.bitset(input.status,      '20'XUL), $
            no_h_lock:   self.bitset(input.status,     '100'XUL), $
            color_kill:  self.bitset(input.status,     '200'XUL), $
            no_sync:     self.bitset(input.status,   '10000'XUL), $
            no_equ:      self.bitset(input.status,   '20000'XUL), $
            no_carrier:  self.bitset(input.status,   '40000'XUL), $
            macrovision: self.bitset(input.status, '1000000'XUL), $
            no_access:   self.bitset(input.status, '2000000'XUL), $
            vtr:         self.bitset(input.status, '4000000'XUL)  $
           }

  capabilities = {dv_timings:  self.bitset(input.capabilities, '2'XUL), $
                  std:         self.bitset(input.capabilities, '4'XUL), $
                  native_size: self.bitset(input.capabilities, '8'XUL)  $
                 }
  
  idlinput = {index: input.index, $
              name: string(input.name), $
              type: (input.type eq 1) ? 'Tuner' : 'Camera', $
              audioset: input.audioset, $
              tuner: input.tuner, $
              std: std, $
              status: status, $
              capabilites: capabilities $
             }
  return, idlinput
end
  
;;;;;
;
; idlv4l2::ParseCapabilities()
;
function idlv4l2::ParseCapabilities, caps

  COMPILE_OPT IDL2, HIDDEN

  res = {V4L2_DEVICE_CAPABILITIES, $
         video_capture:        self.bitset(caps,        '1'XUL), $
         video_capture_mplane: self.bitset(caps,     '1000'XUL), $
         video_output:         self.bitset(caps,        '2'XUL), $
         video_output_mplane:  self.bitset(caps,     '2000'XUL), $
         video_m2m:            self.bitset(caps,     '4000'XUL), $
         video_m2m_mplane:     self.bitset(caps,     '8000'XUL), $
         video_overlay:        self.bitset(caps,        '4'XUL), $
         vbi_capture:          self.bitset(caps,       '10'XUL), $
         vbi_output:           self.bitset(caps,       '20'XUL), $
         sliced_vbi_capture:   self.bitset(caps,       '40'XUL), $
         sliced_vbi_output:    self.bitset(caps,       '80'XUL), $
         rds_capture:          self.bitset(caps,      '100'XUL), $
         video_output_overlay: self.bitset(caps,      '200'XUL), $
         hw_freq_seek:         self.bitset(caps,      '400'XUL), $
         rds_output:           self.bitset(caps,      '800'XUL), $
         tuner:                self.bitset(caps,    '10000'XUL), $
         audio:                self.bitset(caps,    '20000'XUL), $
         radio:                self.bitset(caps,    '40000'XUL), $
         modulator:            self.bitset(caps,    '80000'XUL), $
         sdr_capture:          self.bitset(caps,   '100000'XUL), $
         ext_pix_format:       self.bitset(caps,   '200000'XUL), $
         readwrite:            self.bitset(caps,  '1000000'XUL), $
         asyncio:              self.bitset(caps,  '2000000'XUL), $
         streaming:            self.bitset(caps,  '4000000'XUL), $
         device_caps:          self.bitset(caps, '80000000'XUL)  $
        }

  return, res
end

;;;;;
;
; idlv4l2::GetCapabilities()
;
function idlv4l2::GetCapabilities

  COMPILE_OPT IDL2, HIDDEN

  cap = {v4l2_capability, $
         driver: bytarr(16), $
         card: bytarr(32), $
         bus_info: bytarr(32), $
         version: 0UL, $
         capabilities: 0UL, $
         device_caps: 0UL, $
         reserved: ulonarr(3) $
        }

  self.ioctl, 'VIDIOC_QUERYCAP', cap

  idlcap = {driver: string(cap.driver), $
            card: string(cap.card), $
            bus_info: string(cap.bus_info), $
            version: cap.version, $
            capabilities: self.parsecapabilities(cap.capabilities), $
            device_caps: self.parsecapabilities(cap.device_caps) $
           }
  
  return, idlcap
end

;;;;;
;
; idlv4l2::SetProperty
;
pro idlv4l2::SetProperty, input = input, $
                          width = width, $
                          height = height, $
                          dimensions = dimensions, $
                          greyscale = greyscale, $
                          hflip = hflip, $
                          vflip = vflip

  COMPILE_OPT IDL2, HIDDEN

  if isa(input, /scalar, /number) then $
     self.setinput, input

  doallocate = 0
  if isa(width, /scalar, /number) then begin
     self.setformat, width = width
     doallocate = 1
  endif

  if isa(height, /scalar, /number) then begin
     self.setformat, height = height
     doallocate = 1
  endif
  
  if isa(greyscale, /scalar, /number) then begin
     self.setformat, greyscale = greyscale
     doallocate = 1
  endif

  if isa(dimensions, /number) && $
     (n_elements(dimensions) eq 2) then begin
     self.setformat, width = dimensions[0], height = dimensions[1]
     doallocate = 1
  endif

  if isa(hflip, /number, /scalar) then $
     self.hflip = keyword_set(hflip)

  if isa(vflip, /number, /scalar) then $
     self.vflip = keyword_set(vflip)

  if doallocate then $
     self.allocate
end

;;;;;
;
; idlv4l2::GetProperty
;
pro idlv4l2::GetProperty, device_name = device_name, $
                          fd = fd, $
                          capabilities = capabilities, $
                          input = input, $
                          input_properties = input_properties, $
                          format = format, $
                          width = width, $
                          height = height, $
                          dimensions = dimensions, $
                          greyscale = greyscale, $
                          data = data, $
                          hflip = hflip, $
                          vflip = vflip

  COMPILE_OPT IDL2, HIDDEN

  if arg_present(device_name) then $
     device_name = self.device_name

  if arg_present(fd) then $
     fd = self.fd

  if arg_present(capabilities) then $
     capabilities = self.getcapabilities()

  if arg_present(input) then $
     input = self.getinput()
  
  if arg_present(input_properties) then $
     input_properties = self.getinputproperties()

  format = self.getformat()
  
  if arg_present(width) then $
     width = format.width
 
  if arg_present(height) then $
     height = format.height

  if arg_present(dimensions) then $
     dimensions = [format.width, format.height]
 
  if arg_present(greyscale) then $
     greyscale = ~self.doconvert

  if arg_present(data) then $
     data = (self.doconvert) ? *self._rgb : *self._data

  if arg_present(hflip) then $
     hflip = self.hflip

  if arg_present(vflip) then $
     vflip = self.vflip
end

;;;;;
;
; idlv4l2::Allocate
;
pro idlv4l2::Allocate

  COMPILE_OPT IDL2, HIDDEN

  fmt = self.getformat()
  data = bytarr(fmt.bytesperline, fmt.height)
  
  ptr_free, self._data
  self._data = ptr_new(data, /no_copy)

  ptr_free, self._rgb
  if self.doconvert then begin
     rgb = bytarr(3, fmt.width, fmt.height)
     self._rgb = ptr_new(rgb, /no_copy)
  endif
end

;;;;;
;
; idlv4l2::Init()
;
function idlv4l2::Init, arg, $
                        device_name = device_name, $
                        dimensions = dimensions, $
                        hflip = hflip, $
                        vflip = vflip, $
                        greyscale = greyscale

  COMPILE_OPT IDL2, HIDDEN

  if n_params() eq 1 then $
     device_name = arg
  
  self.device_name = (isa(device_name, 'string')) ? $
                     device_name : '/dev/video0'
  
  openu, fd, self.device_name, /get_lun, /rawio, error = err
  if err then begin
     message, 'Could not open ' + self.device_name, /inf
     return, 0B
  endif
  
  self.fd = fd

  ;;; ioctl requests
  ;;; values obtained by compiling and running the following C program
  ;;;
  ;;; #include <stdio.h>
  ;;; #include <linux/videodev2.h>
  ;;; void main(void)
  ;;; {
  ;;;    printf("%lx\n", VIDIOC_G_FMT);
  ;;;    /* etc... */
  ;;; }
  self.id = hash('VIDIOC_G_FMT',     'C0D05604'XUL, $
                 'VIDIOC_S_FMT',     'C0D05605'XUL, $
                 'VIDIOC_QUERYCTRL', 'C0445624'XUL, $
                 'VIDIOC_G_CTRL',    'C008561B'XUL, $
                 'VIDIOC_S_CTRL',    'C008561C'XUL, $
                 'VIDIOC_G_INPUT',   '80045626'XUL, $
                 'VIDIOC_S_INPUT',   'C0045627'XUL, $
                 'VIDIOC_ENUMINPUT', 'C050561A'XUL, $
                 'VIDIOC_QUERYCAP',  '80685600'XUL  $
                )

  cap = self.getcapabilities()
  if ~cap.capabilities.video_capture then begin
     message, self.device_name + ' is not a video capture device', /inf
     self.cleanup
     return, 0B
  endif

  if ~cap.capabilities.readwrite then begin
     message, self.device_name + ' does not support read()', /inf
     self.cleanup
     return, 0B
  endif
  
  if isa(dimensions, /number) && $
     (n_elements(dimensions) eq 2) then $
        self.setformat, width = dimensions[0], height = dimensions[1]

  if isa(greyscale, /number, /scalar) then $
     self.setformat, greyscale = greyscale

  fmt = self.getformat()
  self.doconvert = strcmp(fmt.pixelformat, 'YUYV')
  
  ;;; can driver perform hflip and vflip?
  c = self.listcontrols()
  self.doflip = ~c.haskey('hflip') || ~c.haskey('vflip')
  
  self.hflip = keyword_set(hflip)
  self.vflip = keyword_set(vflip)
  
  self.allocate

  return, 1B
end

;;;;;
;
; idlv4l2::Cleanup
;
pro idlv4l2::Cleanup

  COMPILE_OPT IDL2, HIDDEN

  ptr_free, self._data
  ptr_free, self._rgb
  close, self.fd
  free_lun, self.fd
end

;;;;;
;
; idlv4l2__define
;
pro idlv4l2__define

  COMPILE_OPT IDL2, HIDDEN

  struct = {IDLV4L2, $
            device_name: '',     $ ; name of device file
            fd: 0L,              $ ; file descriptor of device
            dimensions: [0L, 0], $ ; dimensions of image
            id: obj_new(),       $ ; IDs of IOCTL requests
            hflip: 0L,           $ ; flag: horizontal flip
            vflip: 0L,           $ ; flag: vertical flip
            doflip: 0B,          $ ; flag: perform flips in software
            doconvert: 0B,       $ ; flag: perform RGB conversion in software
            _data: ptr_new(),    $ ; data provided by V4L2 driver
            _rgb: ptr_new()      $ ; RGB data, if needed
           }
end
