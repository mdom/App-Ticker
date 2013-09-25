package App::Ticker::Plugin::GetFeeds;

use Moo;
extends 'App::Ticker::Plugin';
with 'App::Ticker::Role::FetchURL';

use Mojo::ByteStream 'b';
use XML::FeedPP;

has 'feeds' => ( is => 'ro', );

sub run {
    my ($self) = @_;
    push @{ $self->items }, $self->get_feeds();
}

sub get_feeds {
    my $self = shift;
    my @items;
    for my $url ( @{ $self->feeds } ) {
        if ( my ($feed) = $self->get_feed($url) ) {
            $feed->link($url);
            for my $item ( $feed->get_item() ) {
                push @items,
                  App::Ticker::Item->new(
                    item => $item,
                    feed => $feed,
                  );
            }
        }
        return @items;
    }
}

sub get_feed {
    my ( $self, $url, $header ) = @_;
    my $tx = $self->get_url( $url, $header );
    my $feed;
    if ( my $res = $tx->success ) {
        if ( $res->code == 200 ) {
            $feed = XML::FeedPP->new( b( $res->body )->decode );
        }
        return wantarray ? ( $feed, $res ) : $feed;
    }
    return;
}

1;
