package App::Ticker;
use Moo;

use App::Ticker::Item;
use Path::Tiny;
use Scalar::Util qw(blessed);
use Try::Tiny;

use EV;
use AnyEvent;

our $VERSION = '0.01';

has items => ( is => 'rw', default => sub { [] } );

has input =>
  ( is => 'rw', coerce => sub { coerce_to( $_[0], 'App::Ticker::Input::' ) }, default => sub {[]} );
has filter =>
  ( is => 'rw', coerce => sub { coerce_to( $_[0], 'App::Ticker::Filter::' ) }, default => sub {[]} );
has output =>
  ( is => 'rw', coerce => sub { coerce_to( $_[0], 'App::Ticker::Output::' ) }, default => sub {[]} );

has workdir => (
    is      => 'rw',
    default => sub { path( $ENV{HOME} )->child(".ticker") },
);

sub coerce_to {
    my ( $self, $to ) = @_;
    my @list;
    for my $plugin (@$self) {
        next if blessed($plugin);

        my ( $options, $class );
        if ( ref($plugin) eq 'HASH' ) {
            $class   = ( keys %$plugin )[0];
            $options = $plugin->{$class};
        }
        else {
            $class = $plugin;
        }
        substr( $class, 0, 1, $to ) if index( $class, '+' ) == 0;
        eval "require $class";
        if ($@) {
            die "Can't load plugin $class: $@\n";
        }
        push @list, $class->new(%$options);
    }
    return \@list;
}

sub run {
    my $self = shift;

    my $workdir = path( $self->workdir );
    $workdir->mkpath unless $workdir->is_dir;

    chdir($workdir)
      or die "Can't chdir to " . $workdir . "\n";

    my $cv = AnyEvent->condvar;

    for my $plugin ( @{ $self->input } ) {
	my $cb_factory = $self->filter_callback($cv);
        $plugin->run($cv,$cb_factory);
    }
    $cv->recv;
    for my $plugin ( @{ $self->output } ) {
	$plugin->finish();
    }
    return;
}

sub filter_callback {
	my ($self,$cv) = @_;
	return sub {
		my @filter = (@{ $self->filter },@{ $self->output } );
		$cv->begin;
		my $cb; $cb = sub {
			my $item = shift;
			my $plugin = shift @filter;
			if ( not defined $item ) {
				$cv->end;
				return;
			}
			if ( !@filter ) {
				$cb = sub { $cv->end };
			}
			try {
				local $SIG{__WARN__} = sub {
					my $message = shift;
					warn "Warning while processing <" . $item->link . ">: $message\n";
				};
				$plugin->process_item( $item, $cb );
			}
			catch {
				chomp;
				warn "$_\n";
				$cv->end;
			};
		};
	};
}

1;
__END__

=pod

=head1 NAME

App::Ticker - framework to fetch, filter and output rss feeds

=head1 DESCRIPTION

RSS Feeds are still one of the easiest ways to get news from all over
the web. But a lot of feeds needs some proprocessing, maybe the content
is cut off after 120 characters and you would prefer to get the full
content or you want to strip advertisments etc. App::Ticker tries to
provide a general framework to fetch rss feeds, filter them as you like
and then render them with differant output modules.

=head1 ATTRIBUTES

=over 4

=item input

A array reference containing either the names of a input modules or hash
references. Each hash reference should contain one key value pair. The
key is the name of a input module and the value is a hashref with the
options it should be instantiated with.

If the name of the input module starts with a plus sign, it is replaced
with the string I<App::Ticker::Input::>.

=item filter

=item output

=back

=head1 METHODS

=over 4

=item run

Calls the input modules one after the other to generate rss items. For
every item a pipeline is constructed which calls every filter plugin
 and renders the processed item with every provided output module.

=back


=head1 AUTHOR

Mario Domgoergen E<lt>mario@domgoergenE<gt>
