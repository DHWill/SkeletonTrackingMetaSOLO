#!/usr/bin/env python
#
# Redirect data from a UDP connection to a serial port and vice versa.
#
# (C) 2002-2020 Chris Liechti <cliechti@gmx.net>
#
# SPDX-License-Identifier:    BSD-3-Clause

# usage example
# python C:\dependencies\Win64\tcp_serial_redirect.py -c 127.0.0.1:5006 COM3

import sys
import socket
import serial
import time

if __name__ == '__main__':  # noqa
    import argparse

    parser = argparse.ArgumentParser(
        description='Simple Serial to Network (UDP) redirector.',
        epilog="""\
NOTE: no security measures are implemented. Anyone can remotely connect
to this service over the network.

Only one connection at once is supported. When the connection is terminated
it waits for the next connect.
""")

    parser.add_argument(
        'SERIALPORT',
        help="serial port name")

    parser.add_argument(
        'BAUDRATE',
        type=int,
        nargs='?',
        help='set baud rate, default: %(default)s',
        default=9600)

    parser.add_argument(
        '-q', '--quiet',
        action='store_true',
        help='suppress non error messages',
        default=False)

    parser.add_argument(
        '--develop',
        action='store_true',
        help='Development mode, prints Python internals on errors',
        default=False)

    group = parser.add_argument_group('serial port')

    group.add_argument(
        "--bytesize",
        choices=[5, 6, 7, 8],
        type=int,
        help="set bytesize, one of {5 6 7 8}, default: 8",
        default=8)

    group.add_argument(
        "--parity",
        choices=['N', 'E', 'O', 'S', 'M'],
        type=lambda c: c.upper(),
        help="set parity, one of {N E O S M}, default: N",
        default='N')

    group.add_argument(
        "--stopbits",
        choices=[1, 1.5, 2],
        type=float,
        help="set stopbits, one of {1 1.5 2}, default: 1",
        default=1)

    group.add_argument(
        '--rtscts',
        action='store_true',
        help='enable RTS/CTS flow control (default off)',
        default=False)

    group.add_argument(
        '--xonxoff',
        action='store_true',
        help='enable software flow control (default off)',
        default=False)

    group.add_argument(
        '--rts',
        type=int,
        help='set initial RTS line state (possible values: 0, 1)',
        default=None)

    group.add_argument(
        '--dtr',
        type=int,
        help='set initial DTR line state (possible values: 0, 1)',
        default=None)

    group = parser.add_argument_group('network settings')

    exclusive_group = group.add_mutually_exclusive_group()

    exclusive_group.add_argument(
        '-P', '--localport',
        type=int,
        help='local UDP port',
        default=7777)

    exclusive_group.add_argument(
        '-c', '--client',
        metavar='HOST:PORT',
        help='make the connection as a client, instead of running a server',
        default=False)

    args = parser.parse_args()

    # connect to serial port
    ser = serial.Serial(args.SERIALPORT,
        baudrate = args.BAUDRATE,
        bytesize = args.bytesize,
        parity = args.parity,
        stopbits = args.stopbits,
        rtscts = args.rtscts,
        xonxoff = args.xonxoff,
    )

    if args.rts is not None:
        ser.rts = args.rts

    if args.dtr is not None:
        ser.dtr = args.dtr

    #if not args.quiet:
        #sys.stderr.write(
        #    '--- UDP to Serial redirect on {p.name}  {p.baudrate},{p.bytesize},{p.parity},{p.stopbits} ---\n'
        #    '--- type Ctrl-C / BREAK to quit\n'.format(p=ser))

    try:
        intentional_exit = False
        if ser.isOpen():
            ser.flushInput() #flush input buffer, discarding all its contents
            ser.flushOutput()#flush output buffer, aborting current output and discard all that is in buffer
            time.sleep(0.5)  #give the serial port sometime to receive the data
            numOfLines = 0
            
            host, port = args.client.split(':')
            srv = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
            
            while ser.isOpen():
                data = ser.readline()
                srv.sendto(data, (host, int(port)))
    except serial.SerialException as e:
        #sys.stderr.write('Could not open serial port {}: {}\n'.format(ser.name, e))
        exit(0)
    except KeyboardInterrupt:
        intentional_exit = True
        exit(0)
    except socket.error as msg:
        exit(0)
    finally:
        exit(0)

    #sys.stderr.write('\n--- exit ---\n')
    exit(0)