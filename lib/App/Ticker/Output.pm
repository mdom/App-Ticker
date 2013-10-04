package App::Ticker::Output;
use Moo;

has items => ( is => 'rw', default => sub { [] } );

sub process_item {
        my ($self,$item,$cb) = @_;
        push @{$self->items}, $item;
        $cb->($item);
        return;
}

sub finish {
	return;
}

1;

