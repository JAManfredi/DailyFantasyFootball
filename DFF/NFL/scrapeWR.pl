use LWP::Simple;
use HTML::TableExtract;
use HTML::Scrubber;

my $url = 'http://sports.yahoo.com/nfl/stats/byposition?pos=WR&conference=NFL&year=season_2016&timeframe=ToDate&sort=17';

$content = get($url);
die "Couldn't get wr data" unless defined $content;

my $scrubber = HTML::Scrubber->new( allow => [ qw[ table tr td ] ] );
my $scrubbedHTML = $scrubber->scrub($content);
#print($scrubbedHTML);

$te = HTML::TableExtract->new(); #headers => [qw(Name Team G  Rec Tgt Yds Y/G Avg Lng YAC 1stD TD  KR Yds Avg Long TD  PR Yds Avg Long TD  Fum FumL)]);
$te->parse($scrubbedHTML);

open(my $wrFile, '>', 'wr_data.txt');

# Print all matching tables
foreach $ts ($te->tables) {
  #print "Table (", join(',', $ts->coords), "):\n";
  if ($ts->count == 5) {
    $x = 0;
    foreach $row ($ts->rows) {
      if ($x >= 2) {
        $rowText = join('|', @$row);
        $rowText =~ s{ \s }{}gxms; #Remove White Space
        print $wrFile $rowText, "\n";
      }
      $x++;
    }
  }
}

close $wrFile;
print "Done\n";
