package App::Ticker::Filter::LastDay;

use Moo;
extends 'App::Ticker::Plugin';
use POSIX qw(mktime);

sub process_item {
	my ($self,$item,$cb) = @_;

        my $start = mktime(0,0,0,(gmtime)[3..8]) - 86400;
        my $end   = $start + 86399;

	my $t = $item->get_pubDate_epoch;

	if ( $t and $t >= $start and $t <= $end ) {
		$cb->($item);
	}
	else {
		$cb->();
	}
	return;
}

1;
