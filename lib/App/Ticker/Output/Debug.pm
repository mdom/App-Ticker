package App::Ticker::Output::Debug;
use Moo;
extends 'App::Ticker::Plugin';
use Mojo::ByteStream 'b';

sub process_item {
	my ($self,$item) = @_;
	print b($item->title)->encode . " " . $item->pubDate . " " . b($item->id)->sha1_sum . "\n";
	return;
}

1;
