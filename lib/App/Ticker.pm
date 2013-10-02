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

App::Ticker - pluggable feedreeder

=head1 AUTHOR

Mario Domgoergen E<lt>mario@domgoergenE<gt>
