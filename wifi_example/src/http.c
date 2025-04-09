#include "http.h"

#include <zephyr/kernel.h>

static K_SEM_DEFINE(http_response_complete, 0, 1);

static char response_buffer[1024];

// void http_get(const char * hostname, const char * path);

int connect_socket(const char * hostname)
{
    static struct addrinfo hints;
	struct addrinfo *res;
	int st, sock;

	printk("Looking up IP addresses:\n");
    hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	st = getaddrinfo(hostname, HTTP_PORT, &hints, &res);
	if (st != 0) {
		printk("Unable to resolve address, quitting\n");
		return -1;
	}
	printk("getaddrinfo status: %d\n", st);

	dump_addrinfo(res);

	sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
	if (sock < 0)
	{
		printk("Issue setting up socket: %d\n", sock);
		return -1;
	}
	printk("sock = %d\n", sock);

	printk("Connecting to server...\n");
	int connect_result = connect(sock, res->ai_addr, res->ai_addrlen);
	if (connect_result != 0)
	{
		printk("Issue during connect: %d\n", sock);
		return -1;
	}

    return sock;
}

void http_response_cb(struct http_response *rsp,
	enum http_final_call final_data,
	void *user_data)
{
	printk("HTTP Callback: %.*s", rsp->data_len, rsp->recv_buf);

	if (HTTP_DATA_FINAL == final_data){
		printk("\n");
		k_sem_give(&http_response_complete);
	}
}

void http_get_example(const char * hostname, const char * path)
{
	int sock = connect_socket(hostname);
	if (sock < 0)
	{
		printk("Issue setting up socket: %d\n", sock);
		return;
	}

	printk("Connected. Making HTTP request...\n");

	struct http_request req = { 0 };
	int ret;

	req.method = HTTP_GET;
	req.host = hostname;
	req.url = path;
	req.protocol = "HTTP/1.1";
	req.response = http_response_cb;
	req.recv_buf = response_buffer;
	req.recv_buf_len = sizeof(response_buffer);

	/* sock is a file descriptor referencing a socket that has been connected
	* to the HTTP server.
	*/
	ret = http_client_req(sock, &req, 5000, NULL);
	printk("HTTP Client Request returned: %d\n", ret);

	k_sem_take(&http_response_complete, K_FOREVER);

	printk("\nClose socket\n");

	(void)close(sock);
}

void dump_addrinfo(const struct addrinfo *ai)
{
	printk("addrinfo @%p: ai_family=%d, ai_socktype=%d, ai_protocol=%d, "
	       "sa_family=%d, sin_port=%x\n",
	       ai, ai->ai_family, ai->ai_socktype, ai->ai_protocol, ai->ai_addr->sa_family,
	       ntohs(((struct sockaddr_in *)ai->ai_addr)->sin_port));
}

