package App::Ticker::Role::DomainRule;
use Moo::Role;

has 'rules' => ( is => 'rw', default => sub{ [] } );

sub get_rule {
    my ($self,$item) = @_;
    my $url = $item->link
	or return;
    my $host     = Mojo::URL->new($url)->host || '';
    my @segments = ($host);
    my @parts    = split( /\./, $host );
    shift @parts;
    while ( @parts > 1 ) {
        push @segments, join( '.', @parts );
        shift @parts;
    }
    # catch-all-rule
    push @segments,'.';

    for my $segment (@segments) {
        if ( exists $self->rules->{$segment} ) {
            return $self->rules->{$segment};
        }
    }
    return;
}

1;


