#ifndef PICO_EXAMPLE_HTTP_H_
#define PICO_EXAMPLE_HTTP_H_

#include <zephyr/net/http/client.h>
#include <zephyr/posix/netdb.h>

#include "json_definitions.h"

void dump_addrinfo(const struct addrinfo *ai);

void http_get_example(const char * hostname, const char * path);

int json_get_example(const char * hostname, const char * path, struct placeholder_post * post);

void json_post_example(const char * hostname, const char * path, const char * payload);

#endif // PICO_EXAMPLE_HTTP_H_