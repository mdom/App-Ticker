package App::Ticker::Output::Maildir;
use Moo;
extends 'App::Ticker::Output';
with 'App::Ticker::Role::FormatMail';

use Mojo::ByteStream 'b';
use Try::Tiny;
use Path::Tiny;
use Maildir::Lite;

has maildir => ( is => 'rw', required => 1 );

sub process_item {
	my ($self,$item,$cb) = @_;
	my $msg = $self->format_mail($item);
	my $mail = $msg->as_string;
	my $mdir = Maildir::Lite->new( dir=> $self->maildir );
	if ( $mdir->creat_message($mail) ) {
		warn "create message in maildir failed for " . $item->title . "\n";
	}
	$cb->($item);
	return;
}

1;
