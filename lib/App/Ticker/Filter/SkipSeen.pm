package App::Ticker::Filter::SkipSeen;

use Moo;
extends 'App::Ticker::Plugin';

use Path::Tiny;
use Mojo::ByteStream 'b';

has 'depth' => (
	is => 'rw',
	default => 3,
);

sub run {
    my $self = shift;

    my @items;

    for my $item ( @{ $self->items } ) {
        push @items, $item if ! $self->seen($item);
    }
    @{$self->items} = @items;
    return;
}

sub seen {
	my ($self,$item) = @_;
	my $sha1 = b($item->id)->sha1_sum;
	my $workdir = path('seen')->child((split('',$sha1))[0..$self->depth]);
	$workdir->mkpath();
	my $file = $workdir->child($sha1);
	my $seen = $file->exists;
	$file->touchpath() if not $seen;
	return $seen;
};

1;
