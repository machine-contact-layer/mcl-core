#!/usr/bin/env python3
"""
Interval/class-set coding versus a flat bitmap, for MCL capability negotiation.

WHY THIS EXISTS

A compact class-interval encoding was proposed for the v1 capability/version
exchange: instead of one bit per capability, order the capabilities so that the
sets machines actually advertise become contiguous runs, and send the runs.
The appeal is real -- a well-chosen ordering can beat a bitmap. The question is
whether it beats one at MCL's scale, and whether it survives meeting a vendor
whose capability sets were not part of the fitting data.

This script answers both. It is research tooling, not protocol code, and it is
the one place in this repository where Python is permitted (see the freestanding
C99 rule for everything protocol-facing).

COST MODEL

    L_interval = ceil(log2(n+1)) + 2 * runs * ceil(log2 n)

  ceil(log2(n+1))     run count, 0..n
  2 * ceil(log2 n)    a (start, end) pair per run
  L_bitmap = n

RESULT

At n = 4 and n = 8 the comparison is exhaustive over all 2^n subsets, so those
numbers are exact rather than sampled: interval coding costs about twice a
bitmap. It only starts winning near n = 16-32 AND only when sets cluster tightly
under one shared ordering -- and the domain-shift case shows what happens when
that assumption fails. The bitmap cannot fail that way, because it has nothing
fitted to fail.

Conclusion recorded in mcl-core/governance/V1_SCOPE.md section 5.4: use an
ordinary bitmask for v1.
"""

import math
import random


def runs(bits):
    """Number of maximal contiguous runs of set bits."""
    count = 0
    prev = 0
    for b in bits:
        if b and not prev:
            count += 1
        prev = b
    return count


def interval_bits(n, bits):
    return math.ceil(math.log2(n + 1)) + 2 * runs(bits) * math.ceil(math.log2(n))


def exhaustive(n):
    """Every subset. Exact, not sampled."""
    total = 0
    for mask in range(1 << n):
        bits = [(mask >> i) & 1 for i in range(n)]
        total += interval_bits(n, bits)
    return total / float(1 << n)


def clustered(n, trials, seed, permute=False):
    """
    Sets drawn as contiguous clusters. With permute=False the code ordering
    matches the clustering, which is the best case interval coding can have.
    With permute=True the clustering moved but the ordering did not -- the
    domain-shift case, i.e. meeting a vendor the code was not fitted to.
    """
    rng = random.Random(seed)
    order = list(range(n))
    if permute:
        rng.shuffle(order)
    total = 0
    for _ in range(trials):
        start = rng.randrange(n)
        length = rng.randint(1, max(1, n // 4))
        bits = [0] * n
        for i in range(start, min(n, start + length)):
            bits[order[i]] = 1
        total += interval_bits(n, bits)
    return total / float(trials)


def main():
    print("Interval/class-set coding vs flat bitmap")
    print("cost model: ceil(log2(n+1)) + 2*runs*ceil(log2 n)   vs   n bits")
    print()
    print("EXHAUSTIVE over every subset -- exact:")
    print("%-6s %-10s %-16s %s" % ("n", "bitmap", "interval mean", "verdict"))
    for n in (4, 8):
        mean = exhaustive(n)
        print("%-6d %-10d %-16.2f %.1fx worse" % (n, n, mean, mean / n))
    print()
    print("  n=4 is today's transport family count. Interval coding costs")
    print("  double a bitmap there, and the gap widens at n=8.")
    print()

    print("SYNTHETIC clustered sets -- illustrative, distribution is invented:")
    print("%-6s %-10s %-16s %s" % ("n", "bitmap", "interval mean", "after domain shift"))
    for n in (16, 32):
        ideal = clustered(n, 20000, seed=7, permute=False)
        shifted = clustered(n, 20000, seed=7, permute=True)
        print("%-6d %-10d %-16.2f %.2f" % (n, n, ideal, shifted))
    print()
    print("  Interval coding can beat a bitmap at these sizes GIVEN an ordering")
    print("  fitted to the real capability sets. Move the clustering without")
    print("  moving the ordering and it loses to the bitmap it beat. The bitmap")
    print("  is invariant under that shift by construction -- nothing is fitted.")
    print()
    print("  These synthetic rows depend on an invented cluster distribution and")
    print("  are NOT evidence about real machines. They show the failure MODE.")
    print("  Only the exhaustive rows above are exact, and those are the ones")
    print("  the v1 decision rests on.")


if __name__ == "__main__":
    main()
