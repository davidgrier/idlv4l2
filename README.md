# IDLv4l2

**IDL interface for video capture using the Video4Linux2 API**

IDL is the Interactive Data Language, and is a product of
[Exelis Visual Information Solutions](http://www.exelisvis.com)

Video4Linux2 is part of the 
[Linux Media Infrastructure API](http://linuxtv.org/downloads/v4l-dvb-apis/)

IDLv4l2 is licensed under the
[GPLv3](http://www.gnu.org/licenses/licenses.html#GPL).

## What it does

IDLv4l2 is a video framegrabber for IDL.  Its goal is to provide
IDL with the ability to read images directly from video cameras.
Because it is based on the V4L2 API, it works only on GNU/linux
systems and only for cameras supported by V4L2.
It has been tested with IDL 8.3 and IDL 8.4.

Typical Usage:

    camera = IDLv4l2()   ; object associated with first available camera
    tvscl, camera.read() ; display the next image


This package is written and maintained by David G. Grier
(david.grier@nyu.edu)
