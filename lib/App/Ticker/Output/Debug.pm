package App::Ticker::Output::Debug;
use Moo;
extends 'App::Ticker::Output';
use Mojo::ByteStream 'b';
use Try::Tiny;

has 'print' => (
	is => 'rw',
	default => sub { [] },
);

sub process_item {
	my ($self,$item,$cb) = @_;
	for my $prop ( @{$self->print} ) {
		if ( my $val = try { $item->$prop } ) {
			print "$prop: " . b($val)->encode . "\n";
		}
	}
	$cb->($item);
	return;
}

1;
