/*
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <errno.h>

// Wifi specific code
#include <zephyr/net/net_config.h>
#include <zephyr/net/icmp.h>
#include <zephyr/net/net_if.h>
#include <zephyr/net/net_ip.h>
#include <zephyr/net/socket.h>
#include <zephyr/net/wifi_mgmt.h>
#include <zephyr/posix/netdb.h>

// Helper macros
#define SSTRLEN(s) (sizeof(s) - 1)
#define CHECK(r) { if (r < 0) { printf("Error: %d\n", (int)r); exit(1); } }

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
	printk("addrinfo @%p: ai_family=%d, ai_socktype=%d, ai_protocol=%d, "
	       "sa_family=%d, sin_port=%x\n",
	       ai, ai->ai_family, ai->ai_socktype, ai->ai_protocol, ai->ai_addr->sa_family,
	       ntohs(((struct sockaddr_in *)ai->ai_addr)->sin_port));
}

static int icmp_echo_reply_handler(struct net_icmp_ctx *ctx,
				struct net_pkt *pkt,
				struct net_icmp_ip_hdr *hdr,
				struct net_icmp_hdr *icmp_hdr,
				void *user_data)
{
	uint32_t cycles;
	char ipv4[INET_ADDRSTRLEN];
	zsock_inet_ntop(AF_INET, &hdr->ipv4->src, ipv4, INET_ADDRSTRLEN);

	uint32_t *start_cycles = user_data;

	cycles = k_cycle_get_32() - *start_cycles;

	printk("Reply from %s: bytes=%d time=%dms TTL=%d\r\n",
			ipv4,
			ntohs(hdr->ipv4->len),
			((uint32_t)k_cyc_to_ns_floor64(cycles) / 1000000),
			hdr->ipv4->ttl);
}

void ping(char* ipv4_addr, uint8_t count)
{
	uint32_t cycles;
	int ret;
	struct net_icmp_ctx icmp_context;

	// Register handler for echo reply
	ret = net_icmp_init_ctx(&icmp_context, NET_ICMPV4_ECHO_REPLY, 0, icmp_echo_reply_handler);
	if (ret != 0) {
		printk("Failed to init ping, err: %d", ret);
	}

	struct net_icmp_ping_params params;

	struct net_if *iface = net_if_get_default();
	struct sockaddr_in dst_addr;
	net_addr_pton(AF_INET, ipv4_addr, &dst_addr.sin_addr);
	dst_addr.sin_family = AF_INET;

	for (int i = 0; i < count; i++)
	{
		cycles = k_cycle_get_32();
		ret = net_icmp_send_echo_request(&icmp_context, iface, &dst_addr, NULL, &cycles);
		if (ret != 0) {
			printk("Failed to send ping, err: %d", ret);
		}
		k_sleep(K_SECONDS(2));
	}

	net_icmp_cleanup_ctx(&icmp_context);
}

static int wifi_connect()
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

	// Ping Google DNS 4 times
    // ping("8.8.8.8", 4);

	static struct addrinfo hints;
	struct addrinfo *res;
	int st, sock;

	printk("Looking up IP addresses:\n");
    hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	st = getaddrinfo(HTTP_HOST, HTTP_PORT, &hints, &res);
	if (st != 0) {
		printk("Unable to resolve address, quitting\n");
		return 0;
	}
	printk("getaddrinfo status: %d\n", st);

    printk("\nConnecting to HTTP Server:\n");	

	dump_addrinfo(res);

	sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
	if (sock < 0)
	{
		printk("Issue setting up socket: %d\n", sock);
		return 0;
	}
	printk("sock = %d\n", sock);

	printk("Connecting to server...\n");
	int connect_result = connect(sock, res->ai_addr, res->ai_addrlen);
	if (connect_result != 0)
	{
		printk("Issue during connect: %d\n", sock);
		return 0;
	}
	printk("Connected!\nSending request...\n");
	CHECK(send(sock, REQUEST, SSTRLEN(REQUEST), 0));

	printk("Response:\n\n");

	while (1) {
		int len = recv(sock, response, sizeof(response) - 1, 0);

		if (len < 0) {
			printk("Error reading response\n");
			return 0;
		}

		if (len == 0) {
			break;
		}

		response[len] = 0;
		printk("%s", response);
	}

	printk("\nClose socket\n");

	(void)close(sock);

	return 0;
}
 
int main(void)
{
	printk("Starting wifi example...\n");

	wifi_connect();

	return 0;
}
 