#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>

import argparse
import sys
import serial
import time

class Alpaca:
    """Alpaca serial device controller"""
    def __init__(self, serial_port):
        self.baudrate = 115200
        self.serial = serial.Serial(serial_port, self.baudrate, timeout=0.5)

    def init(self):
        """Initialize device and check for 'ok' response."""
        self.serial.write(b'\r')
        self.serial.write(b'version\r')
        data = self.serial.readline().decode(errors='ignore')
        num_tries = 10
        while 'ok' not in data and num_tries > 0:
            data = self.serial.readline().decode(errors='ignore')
            if len(data) == 0:
                self.serial.write(b'\r')
            num_tries -= 1
        return num_tries > 0

    def send(self, data_to_send):
        """Send a command and wait for 'ok' response."""
        data = 'ok'
        while len(data) > 0:
            data = self.serial.readline().decode(errors='ignore')

        if isinstance(data_to_send, str):
            data_to_send = data_to_send.encode()
        self.serial.write(data_to_send + b'\r')

        num_tries = 10
        data = ''
        while 'ok' not in data and num_tries > 0:
            data = self.serial.readline().decode(errors='ignore')
            if len(data) == 0:
                self.serial.write(b'\r')
            num_tries -= 1
        return num_tries > 0

    def send_noclear(self, data_to_send):
        """Send a command without clearing received data."""
        data = 'ok'
        while len(data) > 0:
            data = self.serial.readline().decode(errors='ignore')
        if isinstance(data_to_send, str):
            data_to_send = data_to_send.encode()
        self.serial.write(data_to_send + b'\r')

    def read(self):
        """Read until 'ok' is found or retries exhausted."""
        ret = ''
        data = self.serial.readline().decode(errors='ignore')
        num_tries = 5
        while 'ok' not in data and num_tries > 0:
            data = self.serial.readline().decode(errors='ignore')
            if len(data) == 0:
                self.serial.write(b'\r')
                num_tries -= 1
            else:
                ret += data
        return ret

    def usb_connect(self):
        cmd = 'connect host'
        ret = self.send(cmd)
        if not ret:
            print(f'Failed command: {cmd}')

        cmd = 'usbDevicePower 1'
        ret = self.send(cmd)
        if not ret:
            print(f'Failed command: {cmd}')

        return ret

    def usb_disconnect(self):
        cmd = 'connect none'
        ret = self.send(cmd)
        if not ret:
            print(f'Failed command: {cmd}')

        cmd = 'usbDevicePower 0'
        ret = self.send(cmd)
        if not ret:
            print(f'Failed command: {cmd}')

        return ret

    def power_alpaca_on(self):
        """Power on the Alpaca debug board"""
        return self.send('devicePower 1')

    def power_alpaca_off(self):
        """Power off the debug board"""
        return self.send('devicePower 0')

    def volume_down_press(self):
        return self.send('ttl outputBit 2 1')

    def volume_down_release(self):
        return self.send('ttl outputBit 2 0')

    def volume_up_press(self):
        return self.send('gpio volup 1')

    def volume_up_release(self):
        return self.send('gpio volup 0')

    def power_key_press(self):
        return self.send('ttl outputBit 1 1')

    def power_key_release(self):
        return self.send('ttl outputBit 1 0')

    def close(self):
        """Close the serial port."""
        self.serial.close()

    def board_boot_to_edl(self):
        print('Booting to EDL')
        self.power_off()
        self.power_key_press()
        time.sleep(0.5)
        self.power_on()
        print('Toggle EDL on')
        self.send('ttl outputBit 4 1')
        time.sleep(3.0)
        self.power_key_release()
        print('Toggle EDL off')
        self.send('ttl outputBit 4 0')
        time.sleep(2.0)

    def board_boot_to_uefi(self, wait_time_sec=5.0):
        print('Booting to UEFI')
        self.power_off()
        self.volume_up_press()
        self.power_key_press()
        time.sleep(0.5)
        self.power_on()
        time.sleep(wait_time_sec)
        self.power_key_release()
        self.volume_up_release()

    def board_start(self):
        """Power on and start the board."""
        self.power_off()
        self.send('ttl outputBit 4 0')
        self.power_key_press()
        self.power_on()
        time.sleep(2.0)
        self.power_key_release()

    def power_off(self):
        """Power off the board."""
        ret = self.usb_disconnect()
        if ret:
            ret = self.power_alpaca_off()
        if ret:
            print('Turned off power and USB')
        else:
            print('Unable to turn off power and USB')

    def power_on(self):
        """Power on the board."""
        ret = self.usb_connect()
        if ret:
            ret = self.power_alpaca_on()
        if ret:
            print('Turned on power and USB')
        else:
            print('Unable to turn on power and USB')


def main():
    parser = argparse.ArgumentParser(description="Alpaca control script")
    parser.add_argument("command", choices=["edl", "off", "on", "uefi"], help="Boot mode: edl or uefi")
    parser.add_argument("--port", default="/dev/ttyACM0", help="Serial port (default: /dev/ttyACM0)")
    # /dev/serial/by-id/usb-QUALCOMM_Inc._Embedded_Power_Measurement__EPM__device_*-if01
    args = parser.parse_args()

    alpaca = Alpaca(args.port)
    try:
        if not alpaca.init():
            print("Failed to initialize Alpaca device.", file=sys.stderr)
            sys.exit(1)
        if args.command == "edl":
            alpaca.board_boot_to_edl()
        elif args.command == "off":
            alpaca.power_off()
        elif args.command == "on":
            alpaca.board_start()
        elif args.command == "uefi":
            alpaca.board_boot_to_uefi()
    finally:
        alpaca.close()

if __name__ == "__main__":
    main()
