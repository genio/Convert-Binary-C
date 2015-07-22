################################################################################
#
# $Project: /Convert-Binary-C $
# $Author: mhx $
# $Date: 2004/05/20 20:23:48 +0100 $
# $Revision: 1 $
# $Snapshot: /Convert-Binary-C/0.52 $
# $Source: /t/131_align.t $
#
################################################################################
#
# Copyright (c) 2002-2004 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 190 }

$c = new Convert::Binary::C ShortSize => 2
                          , LongSize  => 4
                          ;

eval { $c->parse(<<ENDC) };

struct a {
  char a;
};

struct b {
  short a;
};

struct c {
  char a;
  char b;
};

struct d {
  char a;
  short b;
};

struct e {
  char a;
  long b;
};

struct f {
  char a;
  union {
    char a;
  } b;
};

union g {
  short a;
  struct {
    char a;
  } b;
};

ENDC

ok($@, '');

#                 ,- Alignment
#                |  ,- CompoundAlignment
@config =      ([1, 1], [1, 2], [1, 4], [2, 1], [2, 2], [2, 4], [4, 1], [4, 2], [4, 4]);

%sizeof = (
  'a' =>       [     1,      1,      1,      1,      2,      2,      1,      2,      4],
  'b' =>       [     2,      2,      2,      2,      2,      2,      2,      2,      4],
  'c' =>       [     2,      2,      2,      2,      2,      2,      2,      2,      4],
  'd' =>       [     3,      3,      3,      4,      4,      4,      4,      4,      4],
  'e' =>       [     5,      5,      5,      6,      6,      6,      8,      8,      8],
  'f' =>       [     2,      2,      2,      2,      4,      4,      2,      4,      8],
  'f.b' =>     [     1,      1,      1,      1,      2,      2,      1,      2,      4],
  'g' =>       [     2,      2,      2,      2,      2,      2,      2,      2,      4],
  'g.b' =>     [     1,      1,      1,      1,      2,      2,      1,      2,      4],
);

%offsetof = (
  'c.b' =>     [     1,      1,      1,      1,      1,      1,      1,      1,      1],
  'd.b' =>     [     1,      1,      1,      2,      2,      2,      2,      2,      2],
  'e.b' =>     [     1,      1,      1,      2,      2,      2,      4,      4,      4],
  'f.b' =>     [     1,      1,      1,      1,      2,      2,      1,      2,      4],
  'f.b.a' =>   [     1,      1,      1,      1,      2,      2,      1,      2,      4],
  'g.b' =>     [     0,      0,      0,      0,      0,      0,      0,      0,      0],
);

for my $i (0 .. $#config) {
  print "# --- Alignment => $config[$i][0], CompoundAlignment => $config[$i][1] ---\n";
  $c->configure(Alignment => $config[$i][0], CompoundAlignment => $config[$i][1]);

  for my $t (sort keys %sizeof) {
    my $s = $c->sizeof($t);
    ok($s, $sizeof{$t}[$i], "sizeof('$t')");
  }

  for my $x (sort keys %offsetof) {
    my($t, $m) = $x =~ /(\w+)\.(.*)/;
    my $o = $c->offsetof($t, $m);
    ok($o, $offsetof{$x}[$i], "offsetof('$t', '$m')");

    my @m = map "$t$_", $c->member($t, $o);
    my $r = $c->typeof($x) =~ /struct|union/ ? qr/^$x/ : qr/^$x$/;
    ok(scalar(grep { $_ =~ $r } @m), 1);
  }
}
