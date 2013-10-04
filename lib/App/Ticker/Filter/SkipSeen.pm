package App::Ticker::Filter::SkipSeen;

use Moo;
extends 'App::Ticker::Filter';

use Path::Tiny;
use Mojo::ByteStream 'b';

has 'depth' => (
	is => 'rw',
	default => 3,
);

sub process_item {
	my ($self,$item,$cb) = @_;

	my $sha1 = b($item->id)->sha1_sum;
	my $workdir = path('seen')->child((split('',$sha1))[0..$self->depth]);
	$workdir->mkpath();
	my $file = $workdir->child($sha1);
	if ( not $file->exists ) {
		$file->touchpath();
		$cb->($item);
	}
	else {
		$cb->();
	}
	return;
}

1;
