#ifndef PICO_EXAMPLE_HTTP_H_
#define PICO_EXAMPLE_HTTP_H_

#include <zephyr/net/http/client.h>
#include <zephyr/posix/netdb.h>

void dump_addrinfo(const struct addrinfo *ai);

void http_get_example(const char * hostname, const char * path);

void json_get_example(const char * hostname, const char * path);

void json_post_example(const char * hostname, const char * path, const char * payload);

#endif // PICO_EXAMPLE_HTTP_H_