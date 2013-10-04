package App::Ticker::Role::FormatMail;
use Moo::Role;

use Encode;
use MIME::Lite;
use Mojo::ByteStream 'b';
use Mojo::Util 'html_unescape';

has send_mail_to   => ( is => 'rw', default => sub { $ENV{USER} } );
has send_mail_from => ( is => 'rw', default => sub { $ENV{USER} } );

sub format_mail {
    my ( $self, $item ) = @_;

    my $msg = MIME::Lite->new(
        From =>
          sprintf( '"%s" <%s>', $item->feed->title, $self->send_mail_from ),
        To      => $self->send_mail_to,
        Subject => encode( 'MIME-Q', html_unescape( $item->title ) ),
        Type    => 'multipart/related',
    );

    my $body = MIME::Lite->new(
        Type => 'text/html',
        Data => b( $item->body )->encode(),
    );

    $body->attr( 'content-type.charset' => 'UTF8' );

    $msg->attach($body);

    $msg->add( 'User-Agent'   => 'feeder' );
    $msg->add( 'X-Ticker-URL' => $item->link );

    return $msg;
}

1;