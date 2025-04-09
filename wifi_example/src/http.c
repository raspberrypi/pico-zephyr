#include "http.h"

#include <zephyr/kernel.h>

#include <zephyr/data/json.h>
#include <zephyr/logging/log.h>
#include <zephyr/net/http/client.h>
#include <zephyr/net/net_config.h>
#include <zephyr/net/net_if.h>
#include <zephyr/net/net_ip.h>
#include <zephyr/net/socket.h>
#include <zephyr/net/wifi_mgmt.h>
#include <zephyr/posix/netdb.h>

#include "json_definitions.h"

LOG_MODULE_REGISTER(http);

#define HTTP_PORT "80"

static K_SEM_DEFINE(json_response_complete, 0, 1);
static K_SEM_DEFINE(http_response_complete, 0, 1);
static const char * json_post_headers[] = { "Content-Type: application/json\r\n", NULL };

// Holds the HTTP response
static char response_buffer[2048];

// Keeps track of JSON parsing result
static struct placeholder_post * returned_placeholder_post = NULL;
static int json_parse_result = -1;

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

static void http_response_cb(struct http_response *rsp,
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

static void json_response_cb(struct http_response *rsp,
	enum http_final_call final_data,
	void *user_data)
{
	printk("JSON Callback: %.*s\n", rsp->data_len, rsp->recv_buf);

	if (rsp->body_found)
	{
		printk("Body:\n");
		printk("%.*s", rsp->body_frag_len, rsp->body_frag_start);

		if (returned_placeholder_post != NULL)
		{
			json_parse_result = json_obj_parse(
				rsp->body_frag_start,
				rsp->body_frag_len,
				placeholder_post_descr,
				ARRAY_SIZE(placeholder_post_descr),
				returned_placeholder_post
			);

			if (json_parse_result < 0)
			{
				LOG_ERR("JSON Parse Error: %d", json_parse_result);
			}
			else
			{
				LOG_DBG("json_obj_parse return code: %d", json_parse_result);
				LOG_DBG("Title: %s", returned_placeholder_post->title);
				LOG_DBG("Body: %s", returned_placeholder_post->body);
				LOG_DBG("User ID: %d", returned_placeholder_post->id);
				LOG_DBG("ID: %d", returned_placeholder_post->userId);
			}
		} else {
			LOG_ERR("No pointer passed to copy JSON GET result to");
		}
	}

	if (HTTP_DATA_FINAL == final_data){
		printk("\n");
		k_sem_give(&json_response_complete);
	}
}

int json_get_example(const char * hostname, const char * path, struct placeholder_post * post)
{
	json_parse_result = -1;
	returned_placeholder_post = post;

	int sock = connect_socket(hostname);
	if (sock < 0)
	{
		printk("Issue setting up socket: %d\n", sock);
		return -1;
	}

	printk("Connected. Get JSON Payload...\n");

	struct http_request req = { 0 };
	int ret;

	req.method = HTTP_GET;
	req.host = hostname;
	req.url = path;
	req.protocol = "HTTP/1.1";
	req.response = json_response_cb;
	req.recv_buf = response_buffer;
	req.recv_buf_len = sizeof(response_buffer);

	/* sock is a file descriptor referencing a socket that has been connected
	* to the HTTP server.
	*/
	ret = http_client_req(sock, &req, 5000, NULL);
	printk("HTTP Client Request returned: %d\n", ret);
	if (ret < 0)
	{
		LOG_ERR("Error sending HTTP Client Request");
		return -1;
	}

	k_sem_take(&json_response_complete, K_FOREVER);

	printk("JSON Response complete\n");

	printk("Close socket\n");

	(void)close(sock);

	return json_parse_result;
}

void json_post_example(const char * hostname, const char * path, const char * payload)
{
    int sock = connect_socket(hostname);
	if (sock < 0)
	{
		printk("Issue setting up socket: %d\n", sock);
		return;
	}

	printk("Connected. Post JSON Payload...\n");

    struct http_request req = { 0 };
	int ret;

	req.method = HTTP_POST;
	req.host = hostname;
	req.url = path;
	req.header_fields = json_post_headers;
	req.protocol = "HTTP/1.1";
	req.response = json_response_cb;
	req.payload = payload;
	req.payload_len = strlen(payload);
	req.recv_buf = response_buffer;
	req.recv_buf_len = sizeof(response_buffer);

	ret = http_client_req(sock, &req, 5000, NULL);
	printk("HTTP Client Request returned: %d\n", ret);

	k_sem_take(&json_response_complete, K_FOREVER);

	printk("JSON Response complete\n");

	printk("Close socket\n");

	(void)close(sock);
}

void dump_addrinfo(const struct addrinfo *ai)
{
	printk("addrinfo @%p: ai_family=%d, ai_socktype=%d, ai_protocol=%d, "
	       "sa_family=%d, sin_port=%x\n",
	       ai, ai->ai_family, ai->ai_socktype, ai->ai_protocol, ai->ai_addr->sa_family,
	       ntohs(((struct sockaddr_in *)ai->ai_addr)->sin_port));
}

