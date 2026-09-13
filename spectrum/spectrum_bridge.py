#!/usr/bin/env python3

import os
import stat
import time


FIFO_PATH = "/tmp/conky-cava.fifo"
OUTPUT_PATH = "/tmp/conky-spectrum.dat"

NUM_BARS = 32
MIN_VALUE = 0
MAX_VALUE = 100


def create_fifo():
    """
    Create the FIFO used by CAVA if it does not already exist.
    """

    if os.path.exists(FIFO_PATH):

        mode = os.stat(FIFO_PATH).st_mode

        if stat.S_ISFIFO(mode):
            return

        print(f"{FIFO_PATH} exists but is not a FIFO.")
        print("Remove it manually before restarting.")
        raise RuntimeError("Invalid FIFO path")

    os.mkfifo(FIFO_PATH)

    print(f"Created FIFO: {FIFO_PATH}")


def parse_frame(line):
    """
    Convert:
        3;7;12;45;...
    into:
        [3, 7, 12, 45, ...]

    Values are clamped between 0 and 100.
    """

    line = line.strip()

    if not line:
        return None

    parts = line.split(";")

    values = []

    for part in parts:

        part = part.strip()

        if not part:
            continue

        try:
            value = int(part)
        except ValueError:
            continue

        value = max(MIN_VALUE, min(MAX_VALUE, value))

        values.append(value)

    if not values:
        return None

    # Force exactly 32 bars
    if len(values) < NUM_BARS:
        values.extend([0] * (NUM_BARS - len(values)))

    elif len(values) > NUM_BARS:
        values = values[:NUM_BARS]

    return values


def write_frame(values):
    """
    Atomically replace the output file so that Conky/Lua
    never sees a partially written frame.
    """

    temporary_path = OUTPUT_PATH + ".tmp"

    with open(temporary_path, "w") as file:
        file.write(" ".join(map(str, values)))
        file.write("\n")

    os.replace(temporary_path, OUTPUT_PATH)


def main():

    create_fifo()

    # Initial empty spectrum
    write_frame([0] * NUM_BARS)

    print("Spectrum bridge started")
    print(f"Input  : {FIFO_PATH}")
    print(f"Output : {OUTPUT_PATH}")
    print(f"Bars   : {NUM_BARS}")

    while True:

        try:

            print("Waiting for CAVA...")

            # Opening a FIFO blocks until CAVA connects.
            with open(FIFO_PATH, "r") as fifo:

                print("CAVA connected.")

                for line in fifo:

                    values = parse_frame(line)

                    if values is None:
                        continue

                    write_frame(values)

        except KeyboardInterrupt:
            print("\nStopping spectrum bridge.")
            break

        except Exception as error:

            print(f"Bridge error: {error}")

            time.sleep(1)


if __name__ == "__main__":
    main()