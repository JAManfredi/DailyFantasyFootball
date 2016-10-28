use LWP::Simple;
use HTML::TableExtract;
use HTML::Scrubber;

my $url = 'http://sports.yahoo.com/nfl/stats/byposition?pos=TE&conference=NFL&year=season_2015&timeframe=ToDate&sort=28';

$content = get($url);
die "Couldn't get te data" unless defined $content;

my $scrubber = HTML::Scrubber->new( allow => [ qw[ table tr td nbsp ] ] );
my $scrubbedHTML = $scrubber->scrub($content);
#print($scrubbedHTML);

$te = HTML::TableExtract->new(); #headers => [qw(Name Team G Rec Tgt Yds Y/G Avg Lng YAC 1stD TD Rush Yds Y/G Avg TD Fum FumL)] );
$te->parse($scrubbedHTML);

open(my $teFile, '>', 'te_data.txt');

# Print all matching tables
foreach $ts ($te->tables) {
  #print "Table (", join(',', $ts->coords), "):\n";
  if ($ts->count == 5) {
    $x = 0;
    foreach $row ($ts->rows) {
      if ($x >= 2) {
        $rowText = join('|', @$row);
        $rowText =~ s{ \s }{}gxms; #Remove White Space
        print $teFile $rowText, "\n";
      }
      $x++;
    }
  }
}

close $teFile;
print "Done\n";
