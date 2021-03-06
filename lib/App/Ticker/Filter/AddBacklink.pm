package App::Ticker::Filter::AddBacklink;
use Moo;
extends 'App::Ticker::Filter';

has text => (
	is => 'rw',
	default => 'Show in Browser',
);

sub process_item {
	my ($self,$item,$cb) = @_;
	my $backlink = sprintf('<div><a href="%s">%s</a></div>',$item->link,$self->text);
	$item->body($item->body . $backlink);
	$cb->($item);
	return;
}

1;
