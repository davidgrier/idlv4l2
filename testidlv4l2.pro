debug = 1
s = idlv4l2_open("/dev/video0", debug = debug)
tvscl, idlv4l2_readframe(s, debug = debug)
tvscl, idlv4l2_readframe(s, debug = debug)
tvscl, idlv4l2_readframe(s, debug = debug)
if n_elements(a) gt 1 then $
   tvscl, a
idlv4l2_close, s, debug = debug
