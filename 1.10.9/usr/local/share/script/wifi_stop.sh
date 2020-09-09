#!/bin/sh

SCRIPT_PATH=/usr/local/share/script

SDIO_MMC="/sys/bus/sdio/devices/mmc1:0001:1"
WIFI_EN_GPIO=124

disable_wifi ()
{
	mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4|tail -n 1`
	echo "${mmci} 0" > /proc/ambarella/mmc_fixed_cd

	${SCRIPT_PATH}/t_gpio.sh ${WIFI_EN_GPIO} 0

	local fWaiting=0
	while [ -e ${SDIO_MMC} ] && [ $fWaiting -le 30 ]; do
		fWaiting=$(($fWaiting + 1))
		sleep 0.1
	done
}

#  Note: wpa_supplicant from bcmdhd does not set interface down when exit.
if [ -e /sys/module/bcmdhd ]; then
	# Note: Need wl to set interface "real down".
	wl down
	wpa_cli -i wlan0 terminate
	ifconfig wlan0 down
fi

killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
echo "killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh"
rm -f /tmp/DIRECT.ssid /tmp/DIRECT.passphrase /tmp/wpa_p2p_done /tmp/wpa_last_event
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null

${SCRIPT_PATH}/unload.sh

disable_wifi

#send net status update message (Network turned off)
/usr/bin/SendToRTOS net_off

#stop cmdyi
if [ -e /tmp/fuse_d/events ]; then
    /sbin/start-stop-daemon -K -p /var/run/eventsCB.pid
fi

#stop ethernet over USB
ETHER_MODE=`cat /tmp/wifi.conf | grep "ETHER_MODE" | cut -c 12-`
if [ "${ETHER_MODE}" == "yes"]; then
	${SCRIPT_PATH}/usb_ether.sh stop
fi

