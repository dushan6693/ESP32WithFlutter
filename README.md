//ESP32WithFlutter this sample app is designed to communicate between the flutter android app and ESP32 Arduino board true Bluetooth #on_testing.


#include "BluetoothSerial.h"
const char *pin = "1234";

String device_name = "ESP32";

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#if !defined(CONFIG_BT_SPP_ENABLED)
#error Serial Bluetooth not available or not enabled. It is only available for the ESP32 chip.
#endif

BluetoothSerial SerialBT;

void setup() {
  Serial.begin(115200);
  SerialBT.begin(device_name);
#ifdef USE_PIN
  SerialBT.setPin(pin);
#endif
}

void loop() {
  if (Serial.available()) {
    SerialBT.write(Serial.read());
  }
  if (SerialBT.available()) {
    Serial.write(SerialBT.read());
  }

SerialBT.println("Hello World");
Serial.println("Hello World");
delay(500);
}
