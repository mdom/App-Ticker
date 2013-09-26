package App::Ticker::Filter::AddBacklink;
use Moo;
extends 'App::Ticker::Plugin';

has text => (
	is => 'rw',
	default => 'Show in Browser',
);

sub process_item {
	my ($self,$item) = @_;
	my $backlink = sprintf('<div><a href="%s">%s</a></div>',$item->link,$self->text);
$DB::single=1;
	$item->body($item->body . $backlink);

	return;
}

1;
