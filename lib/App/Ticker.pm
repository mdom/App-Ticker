package App::Ticker;
use Moo;

use App::Ticker::Item;
use Path::Tiny;
use Scalar::Util qw(blessed);

our $VERSION = '0.01';

has items => ( is => 'rw', default => sub { [] } );
has filter =>
  ( is => 'rw', coerce => sub { coerce_to( $_[0], 'App::Ticker::Filter::' ) } );
has input =>
  ( is => 'rw', coerce => sub { coerce_to( $_[0], 'App::Ticker::Input::' ) } );
has output =>
  ( is => 'rw', coerce => sub { coerce_to( $_[0], 'App::Ticker::Output::' ) } );

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

    for my $plugin ( @{ $self->plugins } ) {
        $plugin->items( $self->items );
        $plugin->run();
    }
    return;
}

1;
__END__

=pod

=head1 NAME

App::Ticker - pluggable feedreeder

=head1 AUTHOR

Mario Domgoergen E<lt>mario@domgoergenE<gt>
