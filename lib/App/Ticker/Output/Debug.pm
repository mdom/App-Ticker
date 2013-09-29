package App::Ticker::Output::Debug;
use Moo;
extends 'App::Ticker::Plugin';
use Mojo::ByteStream 'b';

sub process_item {
	my ($self,$item,$cb) = @_;
	print b($item->body)->encode . "\n";
	$cb->($item);
	return;
}

1;
