/*
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <errno.h>

// Local includes
#include "http.h"
#include "json_definitions.h"
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
	printk("Starting wifi example on %s\n", CONFIG_BOARD_TARGET);

	wifi_connect(WIFI_SSID, WIFI_PSK);

	// Ping Google DNS 4 times
	printk("Pinging 8.8.8.8 to demonstrate connection:\n");
    ping("8.8.8.8", 4);

	printk("Now performing http GET request to google.com...\n");

	http_get_example(HTTP_HOSTNAME, HTTP_PATH);
	k_sleep(K_SECONDS(1));

	struct placeholder_post get_post_result;
	
	int json_get_status = json_get_example(JSON_HOSTNAME, JSON_GET_PATH, &get_post_result);
	if (json_get_status < 0)
	{
		LOG_ERR("Error in json_get_example");
	} else {
		printk("Got JSON result:\n");
		printk("Title: %s\n", get_post_result.title);
		printk("Body: %s\n", get_post_result.body);
		printk("User ID: %d\n", get_post_result.userId);
		printk("ID: %d\n", get_post_result.id);
	}
	k_sleep(K_SECONDS(1));

	struct placeholder_post new_post_result;
	struct placeholder_new_post new_post = { 
		.body = "RPi",
		.title = "Pico",
		.userId = 199
	};

	json_get_status = json_post_example(JSON_HOSTNAME, JSON_POST_PATH, &new_post, &new_post_result);
	if (json_get_status < 0)
	{
		LOG_ERR("Error in json_post_example");
	} else {
		printk("Got JSON result:\n");
		printk("Title: %s\n", new_post_result.title);
		printk("Body: %s\n", new_post_result.body);
		printk("User ID: %d\n", new_post_result.userId);
		printk("ID: %d\n", new_post_result.id);
	}
	k_sleep(K_SECONDS(1));

	return 0;
}
 