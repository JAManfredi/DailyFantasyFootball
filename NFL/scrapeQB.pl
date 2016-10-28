use LWP::Simple;
use HTML::TableExtract;
use HTML::Scrubber;

my $url = 'http://sports.yahoo.com/nfl/stats/byposition?pos=QB&conference=NFL&year=season_2015&timeframe=ToDate&sort=626';

$content = get($url);
die "Couldn't get qb data" unless defined $content;

my $scrubber = HTML::Scrubber->new( allow => [ qw[ table tr td nbsp ] ] );
my $scrubbedHTML = $scrubber->scrub($content);
#print($scrubbedHTML);

$te = HTML::TableExtract->new( headers => [qw(Name Team G QBRat Comp Att Pct Yds Y/G Y/A TD Int Rush Yds Y/G Avg TD Sack YdsL Fum FumL)] );
$te->parse($scrubbedHTML);

open(my $qbFile, '>', 'qb_data.txt');

# Print all matching tables
foreach $ts ($te->tables) {
  #print "Table (", join(',', $ts->coords), "):\n";
  foreach $row ($ts->rows) {
    $rowText = join('|', @$row);
    $rowText =~ s{ \s }{}gxms; #Remove White Space
    print $qbFile $rowText, "\n";
  }
}

close $qbFile;
print "Done\n";
