package App::Ticker::Filter::InlineImages;
use Moo;
extends 'App::Ticker::Plugin';
with 'App::Ticker::Role::FetchURL';

use Mojo::ByteStream 'b';

sub download_image {
    my ( $self, $url ) = @_;
    my $tx = $self->get_url($url);
    if ( my $res = $tx->success ) {
        return if $res->code != '200';
        return $res;
    }
    return;
}

sub process_item {
    my ( $self, $item ) = @_;
    my $i   = 0;
    my $dom = Mojo::DOM->new( $item->body );
    $dom->find('img[src]')->each(
        sub {
            my $node = shift;
            my $url  = $node->attr('src');
            if ( my $res = $self->download_image($url) ) {
                my $mime = $res->headers->content_type;
                $node->attr( src => "data:$mime;base64,".b($res->body)->b64_encode());
            }
            return;
        }
    );
    $item->body( $dom->to_xml );
    return;
}

1;
