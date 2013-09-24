package App::Ticker;
use Moo;

use Mojo::ByteStream 'b';
use Mojo::UserAgent;
use XML::FeedPP;
use App::Ticker::Item;
use Path::Tiny;
use Try::Tiny;
use Scalar::Util qw(blessed);

our $VERSION = '0.01';

has items   => ( is => 'rw', default => sub {[]} );
has plugins => ( is => 'rw' );

has workdir => (
    is      => 'rw',
    default => sub { path( $ENV{HOME} )->child(".ticker") },
    # coerce  => sub {
    #   $_[0] = path( $_[0] ) if !ref( $_[0] );
    #},
);

sub BUILD {
    my $self = shift;
    for my $plugin ( @{ $self->plugins } ) {
        # FIXME add coercion via Type::Tiny
        next if blessed($plugin) && $plugin->isa('App::Ticker::Plugin');

        my $options = {};
	my $class;
        if ( ref($plugin) eq 'HASH' ) {
            $class   = ( keys %$plugin )[0];
            $options = $plugin->{$class};
        }
        else {
            $class = $plugin;
        }
        substr( $class, 0, 1, 'App::Ticker::Plugin::' ) if index( $class, '+' ) == 0;
	eval "require $class";
	if ( $@ ){
		die "Can't load plugin $class: $@\n";
        }
        $plugin = $class->new(%$options, items => $self->items);
    }
    return;
}

sub run {
    my $self = shift;

    my $workdir = path($self->workdir);
    $workdir->mkpath unless $workdir->is_dir;

    chdir($workdir)
	or die "Can't chdir to " . $workdir . "\n";

    for my $plugin ( @{$self->plugins} ) {
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
