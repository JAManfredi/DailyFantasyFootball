use strict;
use warnings;

my @scripts = ('scrapeQB.pl', 'scrapeRB.pl', 'scrapeWR.pl', 'scrapeTE.pl', 'scrapeTeamDefense.pl');
for my $scr (@scripts) {
    my $cmd = "$^X $scr";
    print "Run '$cmd'";
    my $out = qx{$cmd};
    print "--> $out";
}
print "All Scripts Finished Successfully.\n";
