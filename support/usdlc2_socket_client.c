/* Copyright (C) 2014 paul@marrington.net, see /GPL license */
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include <netdb.h>
#include <strings.h>
  
char *uSDLC2_send(int fd, char *data) {
  if (write(fd, data, strlen(data)) < 0 ||
    write(fd, "\n", 1) < 0) {
      return "ERROR writing to socket";
    }
  return NULL;
}
  
char* uSDLC2_socket_client( char *name, char *host, int port, 
char* (*cmdProcessor)(char *cmd, char **params, int np, int fd)) {
  int fd;
  
  fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) return "ERROR opening socket";
  struct hostent *server = gethostbyname(host);
  if (!server) return "ERROR, no such host";

  struct sockaddr_in serv_addr;
  bzero((char *) &serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  bcopy((char *) server->h_addr, 
        (char *) &serv_addr.sin_addr.s_addr,
                 server->h_length);
  serv_addr.sin_port = htons(port);
  
  // make connection
  int cr = connect(fd,
    (struct sockaddr *) &serv_addr, sizeof(serv_addr));
  if (cr < 0) {
    return "ERROR connecting";
  }
  // send connection handle
  if (write(fd, name, strlen(name)) < 0 ||
  write(fd, "\n", 1) < 0) {
    return "ERROR writing header to socket";
  }

  // read commands and respond
  while (1) { // per line
    int np = 0, eol = 0;
    char buffer[8192], *params[32];
    char *buf = buffer, *top = buf + 8192;
    while (!eol) { // per word
      char *word = buf;
      while (1) { // per character
        char ch;
        int numRead = read(fd, &ch, 1);
        if (numRead == -1 && errno == EINTR) continue;
        if (numRead <= 0) { *buf = '\0'; break; }
        if (buf < top) *buf++ = ch;
        if (ch == '\n') eol = 1;    // eol
        if (ch == '\0') break;
      }
      params[np++] = word;
    }
    if (strcmp(params[0], "__end__")) return "__end__";
    char *err =
    (*cmdProcessor)(params[0], params, np, fd);
    if (err != NULL) return err;
  }
  return NULL;
}