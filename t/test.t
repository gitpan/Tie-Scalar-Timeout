
# This -*-perl-*- file is run as part of "make test".
# See "perldoc Test" (or the appropriate Test::* module) for details.
#
BEGIN { print "# Perl version $] under $^O\n" }
BEGIN { require Tie::Scalar::Timeout } 
print 	'',
  "# Tie::Scalar::Timeout version $Tie::Scalar::Timeout::VERSION\n",
  "# Time now: " . scalar(gmtime), " GMT\n",
  "# I'm ", ((chr(65) eq 'A') ? '' : 'not '), "in an ASCII world.\n",
  "#------------------------\n",
;
BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Scalar::Timeout;
$loaded = 1;
print "ok 1\n";
tie my $k, 'Tie::Scalar::Timeout', EXPIRES => '+2s';
print "not " if defined $k; print "ok 2\n";
$k = 123;
print "not " unless $k == 123; print "ok 3\n";
sleep(3);
print "not " if defined $k; print "ok 4\n";
#######################################
# test assigning via tie() and num_uses
tie my $m, 'Tie::Scalar::Timeout', NUM_USES => 3, VALUE => 456;
print "not " unless $m == 456; print "ok 5\n";
for (0..2) { my $tmp = $m }
print "not " if defined $m; print "ok 6\n";
#######################################
# test reassigning a value so num_uses is reset
$m = 789;
print "not " unless $m == 789; print "ok 7\n";
for (0..2) { my $tmp = $m }
print "not " if defined $m; print "ok 8\n";
#######################################
# test a fixed-value expiration policy
tie my $n, 'Tie::Scalar::Timeout', VALUE => 987, NUM_USES => 1, POLICY => 777;
print "not " unless $n == 987; print "ok 9\n";
print "not " unless $n == 777; print "ok 10\n";
#######################################
# test a coderef expiration policy
tie my $p, 'Tie::Scalar::Timeout', VALUE => 654, NUM_USES => 1,
    POLICY => \&expired;
my $is_expired;
print "not " unless $p == 654; print "ok 11\n";
$_ = $p;   # to activate FETCH
print "not " unless $is_expired; print "ok 12\n";
sub expired { $is_expired++ }

