#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Starts process and reads its stdou and stderr.
# Not in background: run_cmd blocks untill command has not exited.
#

import os
import sys
from subprocess import Popen, PIPE
from threading import Thread
from select import select
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter

#

TIMEOUT = 5
BUFSIZE = 0 # unbuffered
LOG_BUFSIZE = 256

def progress(proc, timeout=TIMEOUT):
    running = True
    outs = [proc.stdout, proc.stderr]
    nouts = len(outs)
    max_count = LOG_BUFSIZE
    prev_out = None
    out = None
    count = 0
    nclosed = 0

    print('monitoring thread started.')

    while running:
        try:
            (ready_outs, x0, x1) = select(outs, [], [], timeout)
            n = len(ready_outs)
            if prev_out:
                if prev_out in ready_outs:
                    if count < max_count:
                        out = prev_out
                        count += 1
                    else:
                        if n > 1:
                            i = ready_outs.index(prev_out)
                            if i < n - 1:
                                out = ready_outs[i+1]
                            else:
                                out = ready_outs[0]
                            count = 0
                        else:
                            out = prev_out
                elif n > 0:
                    out = ready_outs[0]
                    count = 0
                else:
                    out = None
            elif n > 0:
                out = ready_outs[0]
                count = 0
            else:
                out = None

            prev_out = out

            if out:
                dat = out.read(1)

                if dat:
                    sys.stdout.write(dat)

                else:
                    outs.remove(out)
                    nclosed += 1

            if nclosed >= nouts:
                running = False

        except BaseException, e:
            print(str(e))
            break

    proc.wait()
    if proc.returncode > 0:
        print('execution failed: %s' % proc.returncode)

def run_cmd(cmd):
    cmd_path = os.path.abspath(cmd)
    print('cmd="%s"' % cmd_path)

    try:
        proc = Popen(cmd_path, bufsize=BUFSIZE, shell=True,
                     stdout=PIPE, stderr=PIPE, close_fds=True,
                     universal_newlines=True)

        th = Thread(target=progress, args=(proc,))
        th.start()
        th.join()

    except (KeyboardInterrupt, SystemExit):
        print('interrupted.')

    except OSError, e:
        print('execution failed: %s' % e)


def main():
    # parser = ArgumentParser(description='Process monitor',
    #                         formatter_class=ArgumentDefaultsHelpFormatter)

    # parser.add_argument('cmd', type=str, metavar='PATH',
    #                     help='command to be monitored')

    # args = parser.parse_args()

    commands = ["./mlframe/scripts/test.sh A","./mlframe/scripts/test.sh B"]
    for cmd in commands:
        run_cmd(cmd)
    print "finished"


if __name__ == '__main__':
    main()