#ifndef _GNU_SOURCE
#define _GNU_SOURCE // support getopt_long
#endif

#include <linux/rfkill.h>
#include <sys/inotify.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <stdbool.h>
#include <inttypes.h>

#ifndef RFKILL_VERSION
#define RFKILL_VERSION "unkown"
#endif

#ifndef DEV_RFKILL
#define DEV_RFKILL "/dev/rfkill"
#endif

char const*
rfkill_type_to_string(enum rfkill_type t) {
  switch(t) {
  case RFKILL_TYPE_ALL:
    return "all";
  case RFKILL_TYPE_WLAN:
    return "wlan";
  case RFKILL_TYPE_BLUETOOTH:
    return "bt";
  case RFKILL_TYPE_UWB:
    return "uwb";
  case RFKILL_TYPE_WIMAX:
    return "wimax";
  case RFKILL_TYPE_WWAN:
    return "wwan";
  case RFKILL_TYPE_GPS:
    return "gps";
  case RFKILL_TYPE_FM:
    return "fm";
  default:
    return "<unknown>";
  }
}

char const *
rfkill_state_to_string(struct rfkill_event const *e) {
  if(e->hard) {
    return "hard blocked";
  }
  else if(e->soft) {
    return "soft blocked";
  }
  return "not blocked";
}

int
open_dev_rfkill(bool write) {
  int const flags = write ? O_RDWR : O_RDONLY;
  int const fd = open(DEV_RFKILL, flags|O_NONBLOCK);
  if(fd == -1) {
    perror("open");
    exit(1);
  }
  return fd;
}

void
list_impl(int fd) {
  struct rfkill_event event;
  ssize_t n;
  puts("id\ttype\tstate");
  while( (n = read(fd, &event, sizeof(event))) >= (ssize_t)sizeof(event) ) {
    printf("%" PRIu32 "\t%s\t%s\n", event.idx, rfkill_type_to_string(event.type),
           rfkill_state_to_string(&event));
  }
  if(n < 0 && errno != EWOULDBLOCK) {
    perror("read");
    close(fd);
    exit(1);
  }
}

void
list(void) {
  int const fd = open_dev_rfkill(false);
  list_impl(fd);
  close(fd);
}

enum rfkill_type
string_to_rfkill_type(char const *str) {
  if(strcasecmp(str, "all") == 0) {
    return RFKILL_TYPE_ALL;
  }
  else if(strcasecmp(str, "wlan") == 0) {
    return RFKILL_TYPE_WLAN;
  }
  else if(strcasecmp(str, "bluetooth") == 0 ||
          strcasecmp(str, "bt") == 0) {
    return RFKILL_TYPE_BLUETOOTH;
  }
  else if(strcasecmp(str, "uwb") == 0) {
    return RFKILL_TYPE_UWB;
  }
  else if(strcasecmp(str, "wimax") == 0) {
    return RFKILL_TYPE_WIMAX;
  }
  else if(strcasecmp(str, "wwan") == 0) {
    return RFKILL_TYPE_WWAN;
  }
  else if(strcasecmp(str, "gps") == 0) {
    return RFKILL_TYPE_GPS;
  }
  else if(strcasecmp(str, "fm") == 0) {
    return RFKILL_TYPE_FM;
  }
  else {
    fprintf(stderr, "Error: unkown type \"%s\"", str);
    exit(1);
  }
}

void
change_state(char const *param, bool block) {
  struct rfkill_event event;
  memset(&event, 0, sizeof(event));
  char *endptr;
  event.idx = strtol(param, &endptr, 10);
  if(*endptr != '\0') { // not an id but a type
    event.type = string_to_rfkill_type(param);
    event.op = RFKILL_OP_CHANGE_ALL;
  }
  else {
    event.op = RFKILL_OP_CHANGE;
  }

  event.soft = block;

  int const fd = open_dev_rfkill(true);
  if(write(fd, &event, sizeof(event)) < 0) {
    perror("Error: write");
    exit(1);
  }

  close(fd);
}

void
listen(void) {
  int const inotifyfd = inotify_init();
  if(inotifyfd == -1) {
    perror("Error: inotify_init");
    exit(1);
  }
  if(inotify_add_watch(inotifyfd, DEV_RFKILL, IN_MODIFY) == -1) {
    perror("Error: inotify_add_watch");
    exit(1);
  }
  int const fd = open_dev_rfkill(false);
  list_impl(fd);
  struct inotify_event e;
  ssize_t n;
  while( (n = read(inotifyfd, &e, sizeof(e))) >= (ssize_t)sizeof(e) ) {
    if( (e.mask & IN_MODIFY) == IN_MODIFY) {
      list_impl(fd);
    }
  }
  if(n < 0) {
    perror("read (inotify)");
    close(fd);
    close(inotifyfd);
    exit(1);
  }
}

void usage(char const *arg0) {
  printf("Usage: %s --[list|help|version|listen] --[unblock|block] <id or type>\n\n"
         "\t-l, --list\tlist rfkill events\n"
         "\t-h, --help\tdisplay this\n"
         "\t-v, --version\tshow version\n"
         "\t-e, --listen\tlisten for new rfkill events\n"
         "\t-u, --unblock <id or type>\ttry to unblock the device with the id or all devices of a certain type.\n"
         "\t-b, --block <id or type>\ttry to soft block the device with the id or all devices of a certain type.\n\n"
         "Type might be one of the following:\n"
         "\tall\tmeans all of the below\n"
         "\twlan\n"
         "\tbluetooth or bt\n"
         "\tuwb\n"
         "\twimax\n"
         "\twwan\n"
         "\tgps\n"
         "\tfm\n\n"
         "For more information about rfkill see Documentation/rfkill.txt "
         "in the kernel source\n", arg0);
}

int main(int argc, char **argv) {
  
  struct option const long_options[] = {
    {"list", 0, 0, 'l'},
    {"unblock", 1, 0, 'u'},
    {"softblock", 1, 0, 'b'},
    {"block", 1, 0, 'b'},
    {"help", 0, 0, 'h'},
    {"version", 0, 0, 'v'},
    {"listen", 0, 0, 'e'},
    {0, 0, 0, 0}
  };
  int c;
  int option_index = 0;
  while( (c = getopt_long(argc, argv, "lu:b:hve", long_options, &option_index)) != -1) {
    switch(c) {
    case 'l':
      list();
      return 0;
    case 'u':
      change_state(optarg, false);
      return 0;
    case 'b':
      change_state(optarg, true);
      return 0;
    case 'e':
      listen();
      return 0;
    case 'h':
      usage(argv[0]);
      return 1;
    case 'v':
      printf("rfkill version %s\n", RFKILL_VERSION);
      return 1;
    }
  }

#if 0
  

  

  if(bt_event.idx != ~0u) {
    struct rfkill_event new_event;
    memset(&new_event, 0, sizeof(new_event));
    new_event.idx = bt_event.idx;
    new_event.type = bt_event.type;
    new_event.op = RFKILL_OP_CHANGE;
    new_event.soft = !bt_event.soft;

    if(write(fd, &new_event, sizeof(new_event)) < (ssize_t)sizeof(new_event)) {
      perror("write");
      return 1;
    }
  }
  else {
    printf("no bt\n");
  }

  close(fd);
#endif
}
