/*
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <errno.h>

// Wifi specific code
#include <zephyr/net/net_config.h>
#include <zephyr/net/net_if.h>
#include <zephyr/net/socket.h>
#include <zephyr/net/wifi_mgmt.h>
#include <zephyr/posix/netdb.h>

/* HTTP server to connect to */
#define HTTP_HOST "google.com"
#define HTTP_PORT "80"
#define HTTP_PATH "/"
#define REQUEST "GET " HTTP_PATH " HTTP/1.1\r\nHost: " HTTP_HOST "\r\n\r\n"

#define WIFI_SSID "my_ssid"
#define WIFI_PSK  "my_password"

static char response[1024];

void dump_addrinfo(const struct addrinfo *ai)
{
	printf("addrinfo @%p: ai_family=%d, ai_socktype=%d, ai_protocol=%d, "
	       "sa_family=%d, sin_port=%x\n",
	       ai, ai->ai_family, ai->ai_socktype, ai->ai_protocol, ai->ai_addr->sa_family,
	       ntohs(((struct sockaddr_in *)ai->ai_addr)->sin_port));
}

static int wifi_connect()
{
	printk("Attempting to connect to network %s...\n", WIFI_SSID);

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

	int ret = net_mgmt(NET_REQUEST_WIFI_CONNECT, iface,
			&cnx_params, sizeof(struct wifi_connect_req_params));
	if (ret) {
		printk("Connection request failed with error: %d\n", ret);
		return -ENOEXEC;
	}

	printk("Connection succeeded.\n");

	int config_init_result = net_config_init_app(NULL, "HTTP GET Example Application");
	printk("config_init_result: %d\n", config_init_result);

	printk("Preparing HTTP GET request for http://" HTTP_HOST
		":" HTTP_PORT HTTP_PATH "\n");

	static struct addrinfo hints;
	struct addrinfo *res;
	int st, sock;

	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	st = getaddrinfo(HTTP_HOST, HTTP_PORT, &hints, &res);
	printk("getaddrinfo status: %d\n", st);

	if (st != 0) {
		printk("Unable to resolve address, quitting\n");
		return 0;
	}

	return 0;
}
 
int main(void)
{
	printk("Starting wifi example...\n");

	wifi_connect();

	return 0;
}
 