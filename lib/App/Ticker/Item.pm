package App::Ticker::Item;
use strict;
use warnings;
use Moo;

has item => (
    is      => 'ro',
    handles => [
        qw(get description title link guid set pubDate copyright language image)
    ]
);

has body => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_body',
);

has id => (
    is   => 'lazy',
);

has feed => (
    is => 'ro',
);

sub _build_body {
    my $self = shift;
    return $self->get('content:encoded') || $self->description();
}

sub _build_id {
    my $self = shift;
    return $self->guid || $self->link;
}

1;
