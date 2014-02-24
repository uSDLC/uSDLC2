/* Copyright (C) 2014 paul@marrington.net, see /GPL license */
char* uSDLC2_socket_client( char *name, char *host, int port, 
char* (*commandProcessor)(char *cmd, char **params,
                          int np, int fd));
char* (uSDLC2_send)(int fd, char *data);