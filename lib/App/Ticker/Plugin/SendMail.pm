package App::Ticker::Plugin::SendMail;

use Moo;
extends 'App::Ticker::Plugin';
with 'App::Ticker::Role::FetchURL';

use Encode;
use MIME::Lite;
use Mojo::ByteStream 'b';
use Mojo::Util 'html_unescape';

has send_mail_to            => ( is => 'rw' );
has send_mail_from          => ( is => 'rw' );
has debug => ( is => 'rw', default => 0 );

sub process_item {
    my ( $self, $item ) = @_;

    my $msg = MIME::Lite->new(
        From =>
          sprintf( '"%s" <%s>', $item->feed->title, $self->send_mail_from ),
        To      => $self->send_mail_to,
        Subject => encode_subject($item->title ),
        Type    => 'multipart/related',
    );

    my $body = MIME::Lite->new(
        Type => 'text/html',
        Data => b($item->body)->encode(),
    );

    $body->attr( 'content-type.charset' => 'UTF8' );

    $msg->attach($body);

    $msg->add( 'User-Agent'   => 'feeder' );
    $msg->add( 'X-Ticker-URL' => $item->link );

    if ( $self->debug ) {
	    $msg->print( \*STDOUT );
		print "\n";
    } else {
	    $msg->send();
    }
    return;
};

sub encode_subject {
    return encode( 'MIME-Q', html_unescape( $_[0] ) );
}

1;
