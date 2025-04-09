/*
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <errno.h>

// Wifi specific code
#include <zephyr/posix/netdb.h>
#include <zephyr/net/http/client.h>
#include <zephyr/net/net_config.h>
#include <zephyr/net/net_if.h>
#include <zephyr/net/net_ip.h>
#include <zephyr/net/socket.h>
#include <zephyr/net/wifi_mgmt.h>

#include "ping.h"

// Helper macros
#define CHECK(r) { if (r < 0) { printf("Error: %d\n", (int)r); exit(1); } }

/* HTTP server to connect to */
#define HTTP_PORT "80"

#define WIFI_SSID "my_ssid"
#define WIFI_PSK  "my_password"

const char HTTP_HOSTNAME[] = "google.com";
const char HTTP_PATH[] = "/";
const char JSON_HOSTNAME[] = "jsonplaceholder.typicode.com";
const char JSON_GET_PATH[] = "/todos/1";
const char JSON_POST_PATH[] = "/posts";

static K_SEM_DEFINE(http_response_complete, 0, 1);
static K_SEM_DEFINE(json_response_complete, 0, 1);

static char response_buffer[1024];

void dump_addrinfo(const struct addrinfo *ai)
{
	printk("addrinfo @%p: ai_family=%d, ai_socktype=%d, ai_protocol=%d, "
	       "sa_family=%d, sin_port=%x\n",
	       ai, ai->ai_family, ai->ai_socktype, ai->ai_protocol, ai->ai_addr->sa_family,
	       ntohs(((struct sockaddr_in *)ai->ai_addr)->sin_port));
}

void wifi_connect()
{
	struct net_if *iface = net_if_get_default();
	struct wifi_connect_req_params cnx_params = { 0 };

	cnx_params.ssid = WIFI_SSID;
	cnx_params.ssid_length = strlen(cnx_params.ssid);
	cnx_params.psk = WIFI_PSK;
	cnx_params.psk_length = strlen(cnx_params.psk);
	cnx_params.band = WIFI_FREQ_BAND_UNKNOWN;
	cnx_params.channel = WIFI_CHANNEL_ANY;
	cnx_params.mfp = WIFI_MFP_OPTIONAL;
	cnx_params.wpa3_ent_mode = WIFI_WPA3_ENTERPRISE_NA;
	cnx_params.eap_ver = 1;
	cnx_params.bandwidth = WIFI_FREQ_BANDWIDTH_20MHZ;
	cnx_params.verify_peer_cert = false;

	int connection_result = 1;
	
	while (connection_result != 0){
		printk("Attempting to connect to network %s...\n", WIFI_SSID);
		connection_result = net_mgmt(NET_REQUEST_WIFI_CONNECT, iface,
				&cnx_params, sizeof(struct wifi_connect_req_params));
		if (connection_result) {
			printk("Connection request failed with error: %d\n", connection_result);
		}
		k_sleep(K_MSEC(1000));
	}

	printk("Connection succeeded.\n");
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

void http_get_example()
{
	static struct addrinfo hints;
	struct addrinfo *res;
	int st, sock;

	printk("Looking up IP addresses:\n");
    hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	st = getaddrinfo(HTTP_HOSTNAME, HTTP_PORT, &hints, &res);
	if (st != 0) {
		printk("Unable to resolve address, quitting\n");
		return;
	}
	printk("getaddrinfo status: %d\n", st);

	dump_addrinfo(res);

	sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
	if (sock < 0)
	{
		printk("Issue setting up socket: %d\n", sock);
		return;
	}
	printk("sock = %d\n", sock);

	printk("Connecting to server...\n");
	int connect_result = connect(sock, res->ai_addr, res->ai_addrlen);
	if (connect_result != 0)
	{
		printk("Issue during connect: %d\n", sock);
		return;
	}

	printk("Connected. Making HTTP request...\n");

	struct http_request req = { 0 };
	int ret;

	req.method = HTTP_GET;
	req.url = JSON_GET_PATH;
	req.host = JSON_HOSTNAME;
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

void json_response_cb(struct http_response *rsp,
	enum http_final_call final_data,
	void *user_data)
{
	printk("JSON Callback: %.*s", rsp->data_len, rsp->recv_buf);

	if (HTTP_DATA_FINAL == final_data){
		printk("\n");
		k_sem_give(&json_response_complete);
	}
}

void json_get_example()
{
	static struct addrinfo hints;
	struct addrinfo *res;
	int st, sock;

	printk("Looking up IP addresses:\n");
    hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	st = getaddrinfo(JSON_HOSTNAME, HTTP_PORT, &hints, &res);
	if (st != 0) {
		printk("Unable to resolve address, quitting\n");
		return;
	}
	printk("getaddrinfo status: %d\n", st);

	dump_addrinfo(res);

	sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
	if (sock < 0)
	{
		printk("Issue setting up socket: %d\n", sock);
		return;
	}
	printk("sock = %d\n", sock);

	printk("Connecting to server...\n");
	int connect_result = connect(sock, res->ai_addr, res->ai_addrlen);
	if (connect_result != 0)
	{
		printk("Issue during connect: %d\n", sock);
		return;
	}

	printk("Connected. Get JSON Payload...\n");

	struct http_request req = { 0 };
	int ret;

	req.method = HTTP_GET;
	req.url = JSON_GET_PATH;
	req.host = JSON_HOSTNAME;
	req.protocol = "HTTP/1.1";
	req.response = json_response_cb;
	req.recv_buf = response_buffer;
	req.recv_buf_len = sizeof(response_buffer);

	/* sock is a file descriptor referencing a socket that has been connected
	* to the HTTP server.
	*/
	ret = http_client_req(sock, &req, 5000, NULL);
	printk("HTTP Client Request returned: %d\n", ret);

	k_sem_take(&json_response_complete, K_FOREVER);
	k_sleep(K_SECONDS(1));

	printk("JSON Response complete\n");

	printk("Post JSON Payload...\n");

	const char * json_header[] = { "Content-Type: application/json\r\n", NULL };
	const char json_post_payload[] = "{\"title\": \"RPi\", \"body\": \"Pico\", \"userId\": 199}";

	req.method = HTTP_POST;
	req.url = JSON_POST_PATH;
	req.host = JSON_HOSTNAME;
	req.header_fields = json_header;
	req.protocol = "HTTP/1.1";
	req.response = json_response_cb;
	req.payload = json_post_payload;
	req.payload_len = strlen(json_post_payload);
	req.recv_buf = response_buffer;
	req.recv_buf_len = sizeof(response_buffer);

	ret = http_client_req(sock, &req, 5000, NULL);
	printk("HTTP Client Request returned: %d\n", ret);

	k_sem_take(&json_response_complete, K_FOREVER);

	printk("JSON Response complete\n");
	k_sleep(K_SECONDS(1));

	printk("Close socket\n");

	(void)close(sock);
}
 
int main(void)
{
	printk("Starting wifi example...\n");

	wifi_connect();

	// Ping Google DNS 4 times
	printk("Pinging 8.8.8.8 to demonstrate connection:\n");
    ping("8.8.8.8", 4);

	printk("Now performing http GET request to google.com...\n");

	http_get_example();
	
	json_get_example();

	return 0;
}
 