#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(main, CONFIG_LOG_DEFAULT_LEVEL);

int main(void)
{
	printk("Zephyr Example Application for Pico\n");

	while (1) {
		printk("Running on %s...\n", CONFIG_BOARD);

		k_sleep(K_MSEC(1000));
	}

	return 0;
}

