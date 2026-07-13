#!/usr/bin/env perl
# repeat-bench.pl — run a command N times, report timing distribution.
# This is a Perl program (NOT sh): run it as `perl repeat-bench.pl ...` or
# directly `./repeat-bench.pl ...`. Do NOT prefix with `sh`.
# Portable: uses Perl core Time::HiRes (present on macOS + most Unix).
# Usage: perl repeat-bench.pl [-n RUNS] [-w WARMUPS] -- CMD [ARGS...]
#   -n RUNS     timed runs (default 10)
#   -w WARMUPS  untimed warmup runs, discarded (default 1)
# Command stdout/stderr are sent to /dev/null so only timing is reported.
# Reports min / median / max / mean / stddev in milliseconds, plus a
# coefficient-of-variation (stddev/mean) as a noise indicator.
use strict; use warnings;
use Time::HiRes qw(time);

my ($runs, $warm) = (10, 1);
while (@ARGV && $ARGV[0] =~ /^-/) {
    my $flag = shift @ARGV;
    last if $flag eq '--';
    if    ($flag eq '-n') { $runs = shift @ARGV; }
    elsif ($flag eq '-w') { $warm = shift @ARGV; }
    else { die "unknown flag: $flag\n"; }
}
die "no command given\n" unless @ARGV;
die "-n must be >= 1\n" unless $runs =~ /^\d+$/ && $runs >= 1;

my @cmd = @ARGV;
my $run_once = sub {
    my $t0 = time();
    my $rc = system('sh', '-c', "@cmd >/dev/null 2>&1");
    my $dt = time() - $t0;
    return ($dt, $rc);
};

# Warmups (discarded)
$run_once->() for (1 .. $warm);

my @samples;
my $fail = 0;
for (1 .. $runs) {
    my ($dt, $rc) = $run_once->();
    $fail++ if $rc != 0;
    push @samples, $dt * 1000.0;   # ms
}

my @s = sort { $a <=> $b } @samples;
my $n = scalar @s;
my $min = $s[0];
my $max = $s[-1];
my $median = ($n % 2) ? $s[int($n/2)] : ($s[$n/2 - 1] + $s[$n/2]) / 2;
my $sum = 0; $sum += $_ for @s;
my $mean = $sum / $n;
my $var = 0; $var += ($_ - $mean) ** 2 for @s;
$var /= $n;                      # population variance
my $sd = sqrt($var);
my $cv = $mean > 0 ? 100 * $sd / $mean : 0;

printf "runs=%d warmups=%d failures=%d  (times in ms)\n", $runs, $warm, $fail;
printf "  min    %9.2f\n", $min;
printf "  median %9.2f\n", $median;
printf "  max    %9.2f\n", $max;
printf "  mean   %9.2f\n", $mean;
printf "  stddev %9.2f  (CV %.1f%%)\n", $sd, $cv;
print  "  NOTE: CV > ~10% means high noise; trust median over mean, and\n";
print  "        rerun on a quiet machine before comparing to a baseline.\n";
warn "WARNING: $fail/$runs runs exited non-zero; timings may be meaningless.\n" if $fail;
