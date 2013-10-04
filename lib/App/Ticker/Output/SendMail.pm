package App::Ticker::Output::SendMail;

use Moo;
extends 'App::Ticker::Output';
with 'App::Ticker::Role::FormatMail';

use Encode;

has debug => ( is => 'rw', default => 0 );

sub process_item {
    my ( $self, $item, $cb ) = @_;

    my $msg = $self->format_mail($item);

    if ( $self->debug ) {
	    $msg->print( \*STDOUT );
		print "\n";
    } else {
	    $msg->send();
    }
    $cb->($item);
    return;
};

1;
