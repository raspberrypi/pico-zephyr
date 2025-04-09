#include "http.h"

#include <zephyr/kernel.h>

void dump_addrinfo(const struct addrinfo *ai)
{
	printk("addrinfo @%p: ai_family=%d, ai_socktype=%d, ai_protocol=%d, "
	       "sa_family=%d, sin_port=%x\n",
	       ai, ai->ai_family, ai->ai_socktype, ai->ai_protocol, ai->ai_addr->sa_family,
	       ntohs(((struct sockaddr_in *)ai->ai_addr)->sin_port));
}

