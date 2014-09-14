//
// idlv4l2.h
//
// IDL-callable interface to video4linux2 video capture devices
//
// Modification history:
// 01/11/2011: Written by David G. Grier, New York University
//
// Copyright (c) 2011 David G. Grier
//

#ifndef IDLV4L2_H_INCLUDED
#define IDLV4L2_H_INCLUDED

#define DEBUG(MSG) if (*(int *) argv[0]) {perror("IDLv4l2: " MSG);}
#define CLEAR(x) memset (&(x), 0, sizeof (x))

struct buffer {
  void * start;
  size_t length;
};

#endif // IDLV4L2_H_INCLUDED
