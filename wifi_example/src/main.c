/*
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <errno.h>

// Local includes
#include "http.h"
#include "ping.h"
#include "wifi.h"
#include "wifi_info.h"

LOG_MODULE_REGISTER(wifi_example);

/* HTTP server to connect to */
const char HTTP_HOSTNAME[] = "google.com";
const char HTTP_PATH[] = "/";
const char JSON_HOSTNAME[] = "jsonplaceholder.typicode.com";
const char JSON_GET_PATH[] = "/posts/1";
const char JSON_POST_PATH[] = "/posts";
const char json_post_payload[] = "{\"title\": \"RPi\", \"body\": \"Pico\", \"userId\": 199}";

int main(void)
{
	printk("Starting wifi example...\n");

	wifi_connect(WIFI_SSID, WIFI_PSK);

	// Ping Google DNS 4 times
	printk("Pinging 8.8.8.8 to demonstrate connection:\n");
    ping("8.8.8.8", 4);

	printk("Now performing http GET request to google.com...\n");

	http_get_example(HTTP_HOSTNAME, HTTP_PATH);
	k_sleep(K_SECONDS(1));
	
	json_get_example(JSON_HOSTNAME, JSON_GET_PATH);
	k_sleep(K_SECONDS(1));

	json_post_example(JSON_HOSTNAME, JSON_POST_PATH, json_post_payload);
	k_sleep(K_SECONDS(1));

	return 0;
}
 