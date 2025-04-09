#include "wifi.h"

#include <zephyr/logging/log.h>
#include <zephyr/net/wifi_mgmt.h>

LOG_MODULE_REGISTER(wifi);

void wifi_connect(const char * ssid, const char * psk)
{
	struct net_if *iface = net_if_get_default();
	struct wifi_connect_req_params cnx_params = { 0 };

	cnx_params.ssid = ssid;
	cnx_params.ssid_length = strlen(cnx_params.ssid);
	cnx_params.psk = psk;
	cnx_params.psk_length = strlen(cnx_params.psk);
    cnx_params.security = WIFI_SECURITY_TYPE_NONE;
	cnx_params.band = WIFI_FREQ_BAND_UNKNOWN;
	cnx_params.channel = WIFI_CHANNEL_ANY;
	cnx_params.mfp = WIFI_MFP_OPTIONAL;
	cnx_params.wpa3_ent_mode = WIFI_WPA3_ENTERPRISE_NA;
	cnx_params.eap_ver = 1;
	cnx_params.bandwidth = WIFI_FREQ_BANDWIDTH_20MHZ;
	cnx_params.verify_peer_cert = false;

	int connection_result = 1;
	
	while (connection_result != 0){
		LOG_INF("Attempting to connect to network %s", ssid);
		connection_result = net_mgmt(NET_REQUEST_WIFI_CONNECT, iface,
				&cnx_params, sizeof(struct wifi_connect_req_params));
		if (connection_result) {
			LOG_ERR("Connection request failed with error: %d\n", connection_result);
		}
		k_sleep(K_MSEC(1000));
	}

	LOG_INF("Connection succeeded.");
}