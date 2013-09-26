package App::Ticker::Plugin;
use Moo;

has 'items' => ( is => 'rw');

sub run {
    my $self = shift;
    for my $item ( @{ $self->items } ) {
        $self->process_item($item);
    }
    return;
}

sub process_item {
	return;
}

1;
