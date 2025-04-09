#ifndef PICO_EXAMPLE_HTTP_H_
#define PICO_EXAMPLE_HTTP_H_

#include <zephyr/net/http/client.h>
#include <zephyr/posix/netdb.h>

#define HTTP_PORT "80"

void dump_addrinfo(const struct addrinfo *ai);

void http_get_example(const char * hostname, const char * path);

// void http_get(const char * hostname, const char * path, http_response_cb_t callback);

#endif // PICO_EXAMPLE_HTTP_H_