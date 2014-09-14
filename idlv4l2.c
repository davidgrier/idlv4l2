/*
  idlv4l2: A Video4Linux2 video capture API for IDL

  Modification history
  01/11/2011 Written by David G. Grier, New York University
  01/29/2011 DGG converted to v4l2_* functions.

  Copyright (c) 2011, David G. Grier
*/

#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/select.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <libv4l2.h>

// IDL support
#include <idl_export.h>

// video4linux2 support
#include <asm/types.h>
#include <linux/videodev2.h>

#include "idlv4l2.h"

struct buffer *     buffers   = NULL; // video capture buffers
static unsigned int n_buffers = 0;    // number of video capture buffers

//
// XIOCTL
//
// Wrapper for ioctl that ignores extraneous interrupts
// while waiting for requests to complete
//
static int xioctl (int fd, int request, void *arg)
{
  int r;
  do {
    r = v4l2_ioctl(fd, request, arg);
  } while ((r == -1) && (errno == EINTR));

  return r;
}

//
// OPEN
//
// Return file descriptor for named device
//
// Arguments:
// argv[0]: IN/FLAG debug
// argv[1]: IN device name
// argv[2]: OUT file descriptor
//
// Returns:
// 1: Success
// 0: Failure
// 
int idlv4l2_open(int argc, char *argv[])
{
  IDL_STRING * device;
  int fd;
  struct stat st;

  device = (IDL_STRING *) argv[1];
  
  // make sure device exists
  if (stat(device->s, &st) == -1) {
    DEBUG("could not stat device");
    return 0;
  }

  // make sure this is a character device
  if (!S_ISCHR(st.st_mode)) { 
    DEBUG("not a character-mode device");
    return 0;
  }

  fd = v4l2_open(device->s, O_RDWR | O_NONBLOCK, 0);

  // make sure device opened
  if (fd == -1) { 
    DEBUG("could not open device");
    return 0;
  }

  *(IDL_LONG *) argv[2] = fd;

  return 1;
}

//
// CLOSE
//
// Close the specified device file
//
// Arguments:
// argv[0]: IN/FLAG debug
// argv[1]: IN device handle
//
// Returns:
// 0: Failure
// 1: Success
//
int idlv4l2_close (int argc, char * argv[])
{
  if (v4l2_close(*(int *) argv[1]) == -1) {
    DEBUG("could not close specified file");
    return 0;
  }

  return 1;
}

//
// INIT
//
// Initialize device to default settings
//
// Arguments:
// argv[0]: IN/FLAG debug
// argv[1]: IN file descriptor
// argv[2]: OUT image width
// argv[3]: OUT image height
//
// Returns:
// 0: Failure
// 1: Success
//
int idlv4l2_init (int argc, char * argv[])
{
  int fd;
  struct v4l2_capability cap;
  struct v4l2_cropcap cropcap;
  struct v4l2_crop crop;
  struct v4l2_format fmt;
  unsigned int min;
  struct v4l2_requestbuffers req;
  struct v4l2_buffer buf;
  
  fd = *(IDL_LONG *) argv[1];

  if (xioctl(fd, VIDIOC_QUERYCAP, &cap) == -1) {
    DEBUG("could not query capture capabilities");
    return 0;
  }

  if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
    DEBUG("device cannot capture video");
    return 0;
  }

  if (!(cap.capabilities & V4L2_CAP_STREAMING)) {
    DEBUG("device does not support streaming IO");
    return 0;
  }

  // Select video input
  CLEAR(cropcap);
  cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (xioctl(fd, VIDIOC_CROPCAP, &cropcap) == 0) {
    crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    crop.c = cropcap.defrect; // reset to default rectangle
    if (xioctl(fd, VIDIOC_S_CROP, &crop) == -1) {
      DEBUG("device does not support cropping");
    }
  }

  // Set default video input
  CLEAR(fmt);
  fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  fmt.fmt.pix.width = 640;
  fmt.fmt.pix.height = 480;
  fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_GREY;
  fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
  if(xioctl(fd, VIDIOC_S_FMT, &fmt) == -1) {
    DEBUG("VIDIOC_S_FMT");
    return 0;
  }

  // Initialize memory mapping
  CLEAR (req);
  req.count  = 4; // request 4 capture buffers on device
  req.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  req.memory = V4L2_MEMORY_MMAP;
  if (xioctl(fd, VIDIOC_REQBUFS, &req) == -1) {
    DEBUG("device does not support memory mapping");
    return 0;
  }

  if (req.count < 2) {
    DEBUG("Insufficient buffer memory on device");
    return 0;
  }

  buffers = calloc(req.count, sizeof(*buffers));
  if (!buffers) {
    DEBUG("could not allocate memory for capture buffers");
    return 0;
  }

  for (n_buffers = 0; n_buffers < req.count; n_buffers++) {
    CLEAR(buf);
    buf.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index  = n_buffers;
    if (xioctl(fd, VIDIOC_QUERYBUF, &buf) == -1) {
      DEBUG("could not query capture buffers");
      return 0; // DGG memory leak?
    }
    buffers[n_buffers].length = buf.length;
    buffers[n_buffers].start = v4l2_mmap(NULL, buf.length,
				         PROT_READ | PROT_WRITE,
				         MAP_SHARED,
				         fd, buf.m.offset);
    if (buffers[n_buffers].start == MAP_FAILED) {
      DEBUG("could not map memory");
      return 0; // DGG memory leak?
    }
  }

  *(IDL_LONG *) argv[2] = (IDL_LONG) fmt.fmt.pix.width;
  *(IDL_LONG *) argv[3] = (IDL_LONG) fmt.fmt.pix.height;
  return 1;
}

//
// UNINIT
//
// Deallocate resources
//
// Arguments:
// argv[0]: IN/FLAG debug
// argv[1]: file descriptor
//
// Returns:
// 0: Failure
// 1: Success
//
int idlv4l2_uninit (int argc, char *argv[])
{
  unsigned int i;

  for (i = 0; i < n_buffers; i++) {
    if (v4l2_munmap(buffers[i].start, buffers[i].length) == -1) {
      DEBUG("could not unmap capture buffer");
      return 0;
    }
  }

  free (buffers);
  return 1;
}

//
// LIST CONTROLS
//
// List all controls on the v4l2 device
//
// Arguments:
// argv[0]: IN/FLAG debug
// argv[1]: IN device descriptor
//
// Returns:
// 0: Failure
// 1: Success
//
struct v4l2_queryctrl queryctrl;
struct v4l2_querymenu querymenu;

void enumerate_menu(int fd)
{
  printf ("  Menu items:\n");

  memset (&querymenu, 0, sizeof (querymenu));
  querymenu.id = queryctrl.id;

  for (querymenu.index = queryctrl.minimum;
     querymenu.index <= queryctrl.maximum;
      querymenu.index++) {
	if (0 == xioctl (fd, VIDIOC_QUERYMENU, &querymenu)) {
		printf ("  %s\n", querymenu.name);
	} else {
		perror ("VIDIOC_QUERYMENU");
	}
  }
}

int idlv4l2_listcontrols (int argc, char *argv[])
{
  int fd;

  fd = *(IDL_LONG *) argv[1];

  memset (&queryctrl, 0, sizeof (queryctrl));

  for (queryctrl.id = V4L2_CID_BASE;
     queryctrl.id < V4L2_CID_LASTP1;
     queryctrl.id++) {
        if (0 == xioctl (fd, VIDIOC_QUERYCTRL, &queryctrl)) {
                if (queryctrl.flags & V4L2_CTRL_FLAG_DISABLED)
                        continue;

                printf ("Control %s\n", queryctrl.name);

                if (queryctrl.type == V4L2_CTRL_TYPE_MENU)
                        enumerate_menu (fd);
        } else {
                if (errno == EINVAL)
                        continue;

                perror ("VIDIOC_QUERYCTRL");
                return 0;
        }
  }

  for (queryctrl.id = V4L2_CID_PRIVATE_BASE;;
     queryctrl.id++) {
        if (0 == xioctl (fd, VIDIOC_QUERYCTRL, &queryctrl)) {
                if (queryctrl.flags & V4L2_CTRL_FLAG_DISABLED)
                        continue;

                printf ("Control %s\n", queryctrl.name);

                if (queryctrl.type == V4L2_CTRL_TYPE_MENU)
                        enumerate_menu (fd);
        } else {
                if (errno == EINVAL)
                        break;

                perror ("VIDIOC_QUERYCTRL");
                return 0; 
        }
  }
  return 1;
}


//
// START CAPTURE
//
// Start video capture stream:
// Queue video capture buffers and ioctl VIDIOC_STREAMON
//
// Arguments:
// argv[0]: IN/FLAG debug
// argv[1]: IN device descriptor
//
// Returns:
// 0: Failure
// 1: Success
//
int idlv4l2_startcapture (int argc, char *argv[])
{
  int fd;
  unsigned int i;
  enum v4l2_buf_type type;
  struct v4l2_buffer buf;

  fd = *(IDL_LONG *) argv[1];

  for (i = 0; i < n_buffers; i++) {
    CLEAR(buf);
    buf.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index  = i;
    if (xioctl(fd, VIDIOC_QBUF, &buf) == -1) {
      DEBUG("could not queue video capture buffer");
      return 0;
    }
  }

  type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (xioctl(fd, VIDIOC_STREAMON, &type) == -1) {
    DEBUG("could not start video capture stream");
    return 0;
  }

  return 1;
}

//
// STOP CAPTURE
//
// Stop the video capture stream with ioctl VIDEOC_STREAMOFF
//
// Arguments:
// argv[0]: IN/FLAG debug
// argv[1]: IN device descriptor
//
// Returns:
// 0: Failure
// 1: Success
//
int idlv4l2_stopcapture (int argc, char *argv[])
{
  int fd;
  enum v4l2_buf_type type;

  fd = *(IDL_LONG *) argv[1];
  type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (xioctl(fd, VIDIOC_STREAMOFF, &type) == -1) {
    DEBUG("could not stop video capture stream");
    return 0;
  }

  return 1;
}

//
// READ FRAME
//
// Wait for next frame to arrive,
// dequeue capture buffer, transfer image data, 
// requeue capture buffer
//
// Arguments:
// argv[0]: IN/FLAG debug
// argv[1]: IN device descriptor
// argv[2]: OUT image data
//
// Returns:
// 0: Failure
// 1: Success
//
int idlv4l2_readframe (int argc, char * argv[])
{
  int fd;
  struct v4l2_buffer buf;
  unsigned int i;
  fd_set fds;
  struct timeval tv;
  int r;

  fd = *(IDL_LONG *) argv[1];

  // Wait for interrupt
  do {
    FD_ZERO(&fds);
    FD_SET(fd, &fds);
    tv.tv_sec = 2; // timeout
    tv.tv_usec = 0;
    r = select(fd + 1, &fds, NULL, NULL, &tv);
  } while ((r == -1) && (errno = EINTR));
  
  if (r <= 0) {
    DEBUG("error while waiting to read from device");
    return 0;
  }

  // Dequeue the most recently filled video capture buffer
  CLEAR(buf);
  buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  buf.memory = V4L2_MEMORY_MMAP;
  if (xioctl(fd, VIDIOC_DQBUF, &buf) == -1) {
    DEBUG("readframe: could not dequeue capture buffer.");
    return 0;
  }

  if (buf.index >= n_buffers) {
    DEBUG("readframe: overran buffers!");
    return 0;
  }

  // Transfer image data to IDL
  memcpy((void *) argv[2], buffers[buf.index].start, (size_t) buf.length);

  // Queue the buffer again
  if (xioctl(fd, VIDIOC_QBUF, &buf) == -1) {
    DEBUG("readframe: could not queue capture buffer");
    return 0;
  }

  return 1;
}
