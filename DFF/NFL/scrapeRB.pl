use LWP::Simple;
use HTML::TableExtract;
use HTML::Scrubber;

my $url = 'http://sports.yahoo.com/nfl/stats/byposition?pos=RB&conference=NFL&year=season_2016&sort=17&timeframe=ToDate';

$content = get($url);
die "Couldn't get rb data" unless defined $content;

my $scrubber = HTML::Scrubber->new( allow => [ qw[ table tr td nbsp ] ] );
my $scrubbedHTML = $scrubber->scrub($content);
#print($scrubbedHTML);

$te = HTML::TableExtract->new( headers => [qw(Name Team G	Rush Yds Y/G Avg TD Rec Tgt Yds Y/G Avg Lng YAC 1stD TD Fum FumL)] );
$te->parse($scrubbedHTML);

open(my $rbFile, '>', 'rb_data.txt');

# Print all matching tables
foreach $ts ($te->tables) {
    #print "Table (", join(',', $ts->coords), "):\n";
    foreach $row ($ts->rows) {
        $rowText = join('|', @$row);
        $rowText =~ s{ \s }{}gxms; #Remove White Space
        print $rbFile $rowText, "\n";
    }
}

close $rbFile;
print "Done\n";
