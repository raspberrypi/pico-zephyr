/*
 * SPDX-License-Identifier: Apache-2.0
 */

 #include <zephyr/kernel.h>
 #include <zephyr/shell/shell.h>
 #include <errno.h>
 
 // Wifi specific code
 #include <zephyr/net/net_if.h>
 #include <zephyr/net/wifi_mgmt.h>

 #define WIFI_SSID "my_ssid"
 #define WIFI_PSK  "my_password"
 
 static int wifi_connect()
 {
	printk("Attempting to connect to network...\n");

	struct net_if *iface = net_if_get_wifi_sta();
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

	printk("Connection succeeded");

	return 0;
 }
 
 int main(void)
 {
	printk("Starting wifi example...\n");

	wifi_connect();

	return 0;
 }
 