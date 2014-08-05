package App::Ticker::Input::GetFeeds;

use Moo;
extends 'App::Ticker::Input';
with 'App::Ticker::Role::FetchURL';

use Mojo::ByteStream 'b';
use XML::FeedPP;
use Try::Tiny;

has 'feeds' => ( is => 'ro', );

sub run {
    my ( $self, $cv, $cb_factory ) = @_;
    for my $url ( @{ $self->feeds } ) {
        $cv->begin;
        $self->get_url(
            $url,
            sub {
                my ( $ua, $tx ) = @_;
                if ( my $res = $tx->success ) {
                    if ( $res->code == 200 ) {
                        my $feed = try { XML::FeedPP->new( b( $res->body )->decode ) };
                        if ($feed) {
                            $feed->link($url);
                            for my $item ( $feed->get_item() ) {
                                $cb_factory->()->(
                                    App::Ticker::Item->new(
                                        item => $item,
                                        feed => $feed,
                                    )
                                );
                            }
                        }
                    }
                }
                $cv->end;
            }
        );
    }
}

1;
