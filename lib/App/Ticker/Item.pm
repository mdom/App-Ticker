package App::Ticker::Item;
use strict;
use warnings;
use Moo;
use XML::TreePP;
use Mojo::ByteStream 'b';

has item => (
    is      => 'ro',
    handles => [qw(get title link guid set copyright language image)]
);

has body => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_body',
);

has id => ( is => 'lazy', );

has feed => ( is => 'ro', );

sub pubDate {
    my $self = shift;
    if ( not @_ and not $self->item->pubDate ) {
        $self->item->pubDate(time);
    }
    return $self->item->pubDate(@_);
}

sub safe_id {
	return b($_[0])->sha1_sum;
}

sub description {
    my $self = shift;

    return $self->item->description(@_) if @_;

    # see https://rt.cpan.org/Public/Bug/Display.html?id=67268
    my $description = $self->item->description || '';
    if ( ref($description) eq 'HASH' ) {
        my $tpp = XML::TreePP->new( xml_decl => '' );
        $description =  $tpp->write($description);
    }
    return $description;
}

sub _build_body {
    my $self = shift;
    return $self->get('content:encoded') || $self->description();
}

sub _build_id {
    my $self = shift;
    return $self->guid || $self->link;
}

1;
