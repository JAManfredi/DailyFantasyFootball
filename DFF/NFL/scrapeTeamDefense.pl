use LWP::Simple;
use HTML::TableExtract;
use HTML::Scrubber;

my $url = 'http://sports.yahoo.com/nfl/stats/byteam?group=Defense&cat=Rankings&conference=NFL&year=season_2015&sort=1124';

$content = get($url);
die "Couldn't get team defense data" unless defined $content;

my $scrubber = HTML::Scrubber->new( allow => [ qw[ table tr td nbsp ] ] );
my $scrubbedHTML = $scrubber->scrub($content);
#print($scrubbedHTML);

$te = HTML::TableExtract->new( headers => [qw(Team G Rush Pass Tot)] );
$te->parse($scrubbedHTML);

open(my $teamDefenseFile, '>', 'team_defense.txt');

# Print all matching tables
foreach $ts ($te->tables) {
  #print "Table (", join(',', $ts->coords), "):\n";
  foreach $row ($ts->rows) {
    $rowText = join('|', @$row);
    $rowText =~ s{ \s }{}gxms; #Remove White Space
    print $teamDefenseFile $rowText, "\n";
  }
}

close $teamDefenseFile;
print "Done\n";
